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

        resource_folder = File.join(output_folder, @resource.id.to_s)
        assert File.exist?(File.join(resource_folder, 'info.json'))
        assert File.exist?(File.join(resource_folder, 'manifest.json'))
        assert File.exist?(File.join(resource_folder, 'full', 'max', '0', 'default.jpg'))

        # Both the "w,h" and width-only "w," forms must exist for every generated size
        assert File.exist?(File.join(resource_folder, 'full', '50,40', '0', 'default.jpg'))
        assert File.exist?(File.join(resource_folder, 'full', '50,', '0', 'default.jpg'))
        assert File.exist?(File.join(resource_folder, '0,0,64,64', '64,64', '0', 'default.jpg'))
        assert File.exist?(File.join(resource_folder, '0,0,64,64', '64,', '0', 'default.jpg'))
        assert File.exist?(File.join(resource_folder, '64,64,36,16', '36,16', '0', 'default.jpg'))
        assert File.exist?(File.join(resource_folder, '64,64,36,16', '36,', '0', 'default.jpg'))

        # The width-only variant is copied locally rather than re-fetched from the source
        assert_equal 1, requested_urls.count { |url| url.end_with?('/info.json') }
        assert requested_urls.any? { |url| url.include?('/0,0,64,64/64,64/0/default.jpg') }
        assert requested_urls.none? { |url| url.include?('/0,0,64,64/64,/0/default.jpg') }

        info = JSON.parse(File.read(File.join(resource_folder, 'info.json')))
        assert_equal 'https://static.example/images/' + @resource.id.to_s, info['id']
        assert_equal 'level0', info['profile']
        assert_nil info['extraQualities']
        assert_nil info['extraFormats']
        assert_equal ['sizeByW'], info['extraFeatures']

        manifest = JSON.parse(File.read(File.join(resource_folder, 'manifest.json')))
        body = manifest.dig('items', 0, 'items', 0, 'items', 0, 'body')
        assert_equal 'https://static.example/images/' + @resource.id.to_s, body.dig('service', 0, 'id')
        assert_equal 'image/jpg', body['format']
      end
    ensure
      httparty_singleton.define_method(:get, original_get)
  end

  test 'defaults to an R2Writer when local is not specified' do
    writer = CreateStaticAssetsJob.new.send(:writer_for, 'static-assets', @resource.id, local: false)
    assert_instance_of Iiif::StaticAssets::Writers::R2Writer, writer
  end

  test 'uses a DiskWriter when local: true is passed' do
    writer = CreateStaticAssetsJob.new.send(:writer_for, '/tmp/static-assets', @resource.id, local: true)
    assert_instance_of Iiif::StaticAssets::Writers::DiskWriter, writer
  end
end