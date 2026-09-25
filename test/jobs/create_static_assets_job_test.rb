require 'test_helper'
require 'tmpdir'

class CreateStaticAssetsJobTest < ActiveJob::TestCase
  setup do
    @project = projects(:one)
    @resource = Resource.create!(project: @project, name: 'Static image')
    @resource.content.attach(
      io: File.open(Rails.root.join('test/fixtures/files/sample_image.jpg')),
      filename: 'sample_image.jpg',
      content_type: 'image/jpeg'
    )
  end

  test 'generates static sizes, tiles, level 0 info, and manifest' do
    source_info = {
      'id' => 'https://cantaloupe.example/iiif/3/source',
      'width' => 100,
      'height' => 80,
      'sizes' => [{ 'width' => 50, 'height' => 40 }],
      'tiles' => [{ 'width' => 64, 'height' => 64, 'scaleFactors' => [1, 2] }],
      'extraQualities' => ['bitonal'],
      'extraFormats' => ['png'],
      'extraFeatures' => ['regionByPct']
    }
    responses = {}
    requested_urls = []
    response_class = Struct.new(:body, :code, :message) do
      def success?
        true
      end
    end

    httparty_singleton = HTTParty.singleton_class
    original_get = httparty_singleton.instance_method(:get)
    httparty_singleton.define_method(:get) do |url|
      requested_urls << url
      responses[url] ||= response_class.new(
        url.end_with?('info.json') ? JSON.generate(source_info) : 'image bytes',
        200,
        'OK'
      )
    end

      Dir.mktmpdir do |output_folder|
        CreateStaticAssetsJob.perform_now(@resource.id, 'https://static.example/images', output_folder, local: true)

        image_folder = File.join(output_folder, 'iiif', 'image', 'v3', @resource.uuid)
        assert File.exist?(File.join(image_folder, 'info.json'))
        assert File.exist?(File.join(output_folder, 'iiif', 'presentation', 'v3', @resource.uuid, 'manifest.json'))
        assert File.exist?(File.join(image_folder, 'full', 'max', '0', 'default.jpg'))

        # Both the "w,h" and width-only "w," forms must exist for every generated size
        assert File.exist?(File.join(image_folder, 'full', '50,40', '0', 'default.jpg'))
        assert File.exist?(File.join(image_folder, 'full', '50,', '0', 'default.jpg'))
        assert File.exist?(File.join(image_folder, '0,0,64,64', '64,64', '0', 'default.jpg'))
        assert File.exist?(File.join(image_folder, '0,0,64,64', '64,', '0', 'default.jpg'))
        assert File.exist?(File.join(image_folder, '64,64,36,16', '36,16', '0', 'default.jpg'))
        assert File.exist?(File.join(image_folder, '64,64,36,16', '36,', '0', 'default.jpg'))

        # The width-only variant is copied locally rather than re-fetched from the source
        assert_equal 1, requested_urls.count { |url| url.end_with?('/info.json') }
        assert requested_urls.any? { |url| url.include?('/0,0,64,64/64,64/0/default.jpg') }
        assert requested_urls.none? { |url| url.include?('/0,0,64,64/64,/0/default.jpg') }

        info = JSON.parse(File.read(File.join(image_folder, 'info.json')))
        assert_equal "https://static.example/images/iiif/image/v3/#{@resource.uuid}", info['id']
        assert_equal 'level0', info['profile']
        assert_nil info['extraQualities']
        assert_nil info['extraFormats']
        assert_equal ['sizeByW'], info['extraFeatures']

        manifest = JSON.parse(File.read(File.join(output_folder, 'iiif', 'presentation', 'v3', @resource.uuid, 'manifest.json')))
        assert_equal "https://static.example/images/iiif/presentation/v3/#{@resource.uuid}/manifest.json", manifest['id']
        body = manifest.dig('items', 0, 'items', 0, 'items', 0, 'body')
        assert_equal "https://static.example/images/iiif/image/v3/#{@resource.uuid}", body.dig('service', 0, 'id')
        assert_equal 'image/jpeg', body['format']
      end
    ensure
      httparty_singleton.define_method(:get, original_get)
  end

  test 'reuses full/max bytes for a "sizes" entry matching the full image, instead of re-fetching' do
    source_info = {
      'id' => 'https://cantaloupe.example/iiif/3/source',
      'width' => 100,
      'height' => 80,
      'sizes' => [{ 'width' => 50, 'height' => 40 }, { 'width' => 100, 'height' => 80 }]
    }
    requested_urls = []
    response_class = Struct.new(:body, :code, :message) do
      def success?
        true
      end
    end

    httparty_singleton = HTTParty.singleton_class
    original_get = httparty_singleton.instance_method(:get)
    httparty_singleton.define_method(:get) do |url|
      requested_urls << url
      response_class.new(
        url.end_with?('info.json') ? JSON.generate(source_info) : "bytes for #{url}",
        200,
        'OK'
      )
    end

    Dir.mktmpdir do |output_folder|
      CreateStaticAssetsJob.perform_now(@resource.id, 'https://static.example/images', output_folder, local: true)

      image_folder = File.join(output_folder, 'iiif', 'image', 'v3', @resource.uuid)
      max_bytes = File.read(File.join(image_folder, 'full', 'max', '0', 'default.jpg'))

      # Both paths for the full-size "sizes" entry exist, and contain the same bytes as full/max
      assert_equal max_bytes, File.read(File.join(image_folder, 'full', '100,80', '0', 'default.jpg'))
      assert_equal max_bytes, File.read(File.join(image_folder, 'full', '100,', '0', 'default.jpg'))

      # Only the true downscaled size and full/max were actually fetched from the source
      assert requested_urls.none? { |url| url.include?('/full/100,80/') }
      assert requested_urls.any? { |url| url.include?('/full/50,40/') }
    end
  ensure
    httparty_singleton.define_method(:get, original_get)
  end

  test 'generates per-page assets, a whole-document info.json, and a multi-canvas manifest for PDFs' do
    pdf_resource = Resource.create!(project: @project, name: 'Static PDF', pages_count: 2)
    pdf_resource.content.attach(
      io: File.open(Rails.root.join('test/fixtures/files/sample_multi_page.pdf')),
      filename: 'sample_multi_page.pdf',
      content_type: 'application/pdf'
    )
    1.upto(2) do |page_number|
      pdf_resource.content_converted_pages.attach(
        io: StringIO.new("page #{page_number}"),
        filename: "sample_multi_page_page_#{page_number}.tif",
        content_type: 'image/tiff',
        metadata: { original_page_number: page_number }
      )
    end
    pdf_resource.reload

    page_base_urls = {
      1 => pdf_resource.content_converted_pages_base_url(1),
      2 => pdf_resource.content_converted_pages_base_url(2)
    }
    page_infos = {
      1 => { 'id' => page_base_urls[1], 'width' => 100, 'height' => 80 },
      2 => { 'id' => page_base_urls[2], 'width' => 60, 'height' => 50 }
    }
    requested_urls = []
    response_class = Struct.new(:body, :code, :message) do
      def success?
        true
      end
    end

    httparty_singleton = HTTParty.singleton_class
    original_get = httparty_singleton.instance_method(:get)
    httparty_singleton.define_method(:get) do |url|
      requested_urls << url
      page_number = url.start_with?(page_base_urls[1]) ? 1 : 2

      response_class.new(
        url.end_with?('info.json') ? JSON.generate(page_infos[page_number]) : "page #{page_number} bytes",
        200,
        'OK'
      )
    end

    Dir.mktmpdir do |output_folder|
      CreateStaticAssetsJob.perform_now(pdf_resource.id, 'https://static.example/images', output_folder, local: true)

      image_folder = File.join(output_folder, 'iiif', 'image', 'v3', pdf_resource.uuid)
      assert File.exist?(File.join(image_folder, 'page', '1', 'info.json'))
      assert File.exist?(File.join(image_folder, 'page', '1', 'full', 'max', '0', 'default.jpg'))
      assert File.exist?(File.join(image_folder, 'page', '2', 'info.json'))
      assert File.exist?(File.join(image_folder, 'page', '2', 'full', 'max', '0', 'default.jpg'))

      manifest_path = File.join(output_folder, 'iiif', 'presentation', 'v3', pdf_resource.uuid, 'manifest.json')
      assert File.exist?(manifest_path)

      # A multi-page PDF has no single IIIF Image API representation, so there's no
      # whole-document info.json - only per-page info.json and the presentation manifest.
      assert_not File.exist?(File.join(image_folder, 'info.json'))

      page_1_info = JSON.parse(File.read(File.join(image_folder, 'page', '1', 'info.json')))
      assert_equal "https://static.example/images/iiif/image/v3/#{pdf_resource.uuid}/page/1", page_1_info['id']
      assert_equal 'level0', page_1_info['profile']

      manifest = JSON.parse(File.read(manifest_path))
      assert_equal 2, manifest['items'].size
      first_canvas = manifest['items'][0]
      assert_equal 100, first_canvas['width']
      second_canvas = manifest['items'][1]
      assert_equal 60, second_canvas['width']
      assert_equal(
        "https://static.example/images/iiif/image/v3/#{pdf_resource.uuid}/page/2",
        second_canvas.dig('items', 0, 'items', 0, 'body', 'service', 0, 'id')
      )
    end
  ensure
    httparty_singleton.define_method(:get, original_get)
  end

  test 'skips PDF pages with no converted attachment instead of raising' do
    pdf_resource = Resource.create!(project: @project, name: 'Static PDF With Gap', pages_count: 2)
    pdf_resource.content.attach(
      io: File.open(Rails.root.join('test/fixtures/files/sample_multi_page.pdf')),
      filename: 'sample_multi_page.pdf',
      content_type: 'application/pdf'
    )
    # Page 1 failed to convert; only page 2 has a converted attachment.
    pdf_resource.content_converted_pages.attach(
      io: StringIO.new('page 2'),
      filename: 'sample_multi_page_page_2.tif',
      content_type: 'image/tiff',
      metadata: { original_page_number: 2 }
    )
    pdf_resource.reload

    page_2_base_url = pdf_resource.content_converted_pages_base_url(2)
    page_2_info = { 'id' => page_2_base_url, 'width' => 60, 'height' => 50 }
    response_class = Struct.new(:body, :code, :message) do
      def success?
        true
      end
    end

    httparty_singleton = HTTParty.singleton_class
    original_get = httparty_singleton.instance_method(:get)
    httparty_singleton.define_method(:get) do |url|
      response_class.new(
        url.end_with?('info.json') ? JSON.generate(page_2_info) : 'page 2 bytes',
        200,
        'OK'
      )
    end

    Dir.mktmpdir do |output_folder|
      CreateStaticAssetsJob.perform_now(pdf_resource.id, 'https://static.example/images', output_folder, local: true)

      image_folder = File.join(output_folder, 'iiif', 'image', 'v3', pdf_resource.uuid)
      assert_not File.exist?(File.join(image_folder, 'page', '1', 'info.json'))
      assert File.exist?(File.join(image_folder, 'page', '2', 'info.json'))

      manifest = JSON.parse(File.read(File.join(output_folder, 'iiif', 'presentation', 'v3', pdf_resource.uuid, 'manifest.json')))
      assert_equal 1, manifest['items'].size
      assert_equal "https://static.example/images/iiif/image/v3/#{pdf_resource.uuid}/page/2/canvas/2", manifest['items'][0]['id']
    end
  ensure
    httparty_singleton.define_method(:get, original_get)
  end

  test 'defaults to an R2Writer when local is not specified' do
    writer = CreateStaticAssetsJob.new.send(:writer_for, 'static-assets', local: false)
    assert_instance_of Iiif::StaticAssets::Writers::R2Writer, writer
  end

  test 'uses a DiskWriter when local: true is passed' do
    writer = CreateStaticAssetsJob.new.send(:writer_for, '/tmp/static-assets', local: true)
    assert_instance_of Iiif::StaticAssets::Writers::DiskWriter, writer
  end

  test 'uses an explicit identifier instead of the resource uuid when provided' do
    source_info = { 'id' => 'https://cantaloupe.example/iiif/3/source', 'width' => 10, 'height' => 10 }
    response_class = Struct.new(:body, :code, :message) do
      def success?
        true
      end
    end

    httparty_singleton = HTTParty.singleton_class
    original_get = httparty_singleton.instance_method(:get)
    httparty_singleton.define_method(:get) do |url|
      response_class.new(url.end_with?('info.json') ? JSON.generate(source_info) : 'bytes', 200, 'OK')
    end

    Dir.mktmpdir do |output_folder|
      CreateStaticAssetsJob.perform_now(@resource.id, 'https://static.example/images', output_folder, identifier: 'custom-id', local: true)

      assert File.exist?(File.join(output_folder, 'iiif', 'image', 'v3', 'custom-id', 'info.json'))
      assert File.exist?(File.join(output_folder, 'iiif', 'presentation', 'v3', 'custom-id', 'manifest.json'))
    end
  ensure
    httparty_singleton.define_method(:get, original_get)
  end
end