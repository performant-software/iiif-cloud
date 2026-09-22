require "test_helper"

class ConvertImageJobTest < ActiveJob::TestCase
  setup do
    @project = projects(:one)
  end

  # Test 1: Backwards compatibility - existing image conversion still works
  test "converts image resource to TIFF (backwards compatible)" do
    resource = Resource.create!(
      project: @project,
      name: "Test Image"
    )

    # Attach a test image file
    image_path = Rails.root.join("test/fixtures/files/sample_image.jpg")
    resource.content.attach(
      io: File.open(image_path),
      filename: "sample_image.jpg",
      content_type: "image/jpeg"
    )

    # Perform the job
    ConvertImageJob.perform_now(resource.id)

    # Reload resource to get updated attachments
    resource.reload

    # Verify that content_converted is attached (backwards compatible)
    assert resource.content_converted.attached?, "content_converted should be attached for images"
    
    # Verify that content_converted_pages is NOT attached for images
    assert !resource.content_converted_pages.attached?, "content_converted_pages should not be attached for single images"
    
    # Verify the file is a TIFF
    assert resource.content_converted.filename.to_s.ends_with?(".tif"), "Converted file should be TIFF"
  end

  test "retains the existing conversion when attaching a new conversion fails" do
    resource = Resource.create!(project: @project, name: "Image With Existing Conversion")
    image_path = Rails.root.join("test/fixtures/files/sample_image.jpg")
    resource.content.attach(
      io: File.open(image_path),
      filename: "sample_image.jpg",
      content_type: "image/jpeg"
    )
    resource.content_converted.attach(
      io: StringIO.new("existing conversion"),
      filename: "existing.tif",
      content_type: "image/tiff"
    )
    original_blob_id = resource.content_converted.blob_id
    converted_blob_ids = ActiveStorage::Blob.where(filename: "sample_image.tif").pluck(:id)

    resource.define_singleton_method(:save) { false }

    assert_raises ActiveRecord::RecordNotSaved do
      ConvertImageJob.new.send(:convert_image, resource)
    end

    resource.reload
    assert_equal original_blob_id, resource.content_converted.blob_id
    assert_equal converted_blob_ids, ActiveStorage::Blob.where(filename: "sample_image.tif").pluck(:id)
  end

  # Test 2: PDF conversion stores pages in content_converted_pages
  test "converts multi-page PDF to ordered TIFF set" do
    resource = Resource.create!(
      project: @project,
      name: "Test PDF"
    )

    # Attach a test PDF file
    pdf_path = Rails.root.join("test/fixtures/files/sample_multi_page.pdf")
    resource.content.attach(
      io: File.open(pdf_path),
      filename: "sample_multi_page.pdf",
      content_type: "application/pdf"
    )

    # Perform the job
    ConvertImageJob.perform_now(resource.id)

    # Reload resource to get updated attachments
    resource.reload

    # Verify that content_converted is NOT attached for PDFs
    assert !resource.content_converted.attached?, "content_converted should not be attached for PDFs"
    
    # Verify that content_converted_pages is attached
    assert resource.content_converted_pages.attached?, "content_converted_pages should be attached for PDFs"
    
    # Verify all files are TIFF
    resource.content_converted_pages.each do |page|
      assert page.filename.to_s.ends_with?(".tif"), "All page files should be TIFF"
    end

    # Verify each page retains its original PDF position
    resource.content_converted_pages.each_with_index do |page, index|
      assert_equal index + 1, page.blob.metadata['original_page_number']
    end

    # Verify pages_count is stored
    expected_page_count = 3  # sample_multi_page.pdf should have 3 pages
    assert_equal expected_page_count, resource.pages_count, "pages_count should be stored"
    
    # Verify attachments count matches page count
    assert_equal expected_page_count, resource.content_converted_pages.count, "Number of attachments should match page count"
  end

  test "retains existing converted pages when publishing a new page set fails" do
    resource = Resource.create!(project: @project, name: "PDF With Existing Converted Page")
    pdf_path = Rails.root.join("test/fixtures/files/sample_multi_page.pdf")
    resource.content.attach(
      io: File.open(pdf_path),
      filename: "sample_multi_page.pdf",
      content_type: "application/pdf"
    )
    resource.content_converted_pages.attach(
      io: StringIO.new("existing converted page"),
      filename: "existing_page.tif",
      content_type: "image/tiff",
      metadata: { original_page_number: 1 }
    )
    original_page_blob_ids = resource.content_converted_pages.map(&:blob_id)
    original_blob_ids = ActiveStorage::Blob.pluck(:id).sort

    save_calls = 0
    original_save = resource.method(:save!)
    resource.define_singleton_method(:save!) do |*args, **kwargs|
      save_calls += 1
      raise ActiveRecord::RecordNotSaved, "Unable to publish converted pages" if save_calls == 2

      original_save.call(*args, **kwargs)
    end

    assert_raises ActiveRecord::RecordNotSaved do
      ConvertImageJob.new.send(:convert_pdf, resource)
    end

    resource.reload
    assert_equal original_page_blob_ids, resource.content_converted_pages.map(&:blob_id)
    assert_equal original_blob_ids, ActiveStorage::Blob.pluck(:id).sort
    assert_equal "failed", resource.conversion_status
  end

  test "looks up converted PDF pages by original page number" do
    resource = Resource.create!(
      project: @project,
      name: "PDF With Failed Page",
      pages_count: 4
    )

    1.upto(4) do |page_number|
      next if page_number == 3

      resource.content_converted_pages.attach(
        io: StringIO.new("page #{page_number}"),
        content_type: "image/tiff",
        filename: "document_page_#{page_number}.tif",
        metadata: { original_page_number: page_number }
      )
    end

    resource.reload

    assert_nil resource.content_converted_pages_base_url(3)
    assert_includes resource.content_converted_pages_base_url(4), resource.content_converted_pages.last.key
  end

  # Test 3: Image resource doesn't set pages_count
  test "image conversion does not set pages_count" do
    resource = Resource.create!(
      project: @project,
      name: "Test Image"
    )

    image_path = Rails.root.join("test/fixtures/files/sample_image.jpg")
    resource.content.attach(
      io: File.open(image_path),
      filename: "sample_image.jpg",
      content_type: "image/jpeg"
    )

    ConvertImageJob.perform_now(resource.id)
    resource.reload

    # pages_count should remain nil for images
    assert_nil resource.pages_count, "pages_count should be nil for images"
  end

  # Test 4: Resource model helper methods work correctly
  test "resource helper methods distinguish single vs multi-page conversions" do
    image_resource = Resource.create!(
      project: @project,
      name: "Image Resource"
    )
    
    pdf_resource = Resource.create!(
      project: @project,
      name: "PDF Resource"
    )

    # Attach files
    image_path = Rails.root.join("test/fixtures/files/sample_image.jpg")
    image_resource.content.attach(
      io: File.open(image_path),
      filename: "sample_image.jpg",
      content_type: "image/jpeg"
    )

    pdf_path = Rails.root.join("test/fixtures/files/sample_multi_page.pdf")
    pdf_resource.content.attach(
      io: File.open(pdf_path),
      filename: "sample_multi_page.pdf",
      content_type: "application/pdf"
    )

    # Run conversions
    ConvertImageJob.perform_now(image_resource.id)
    ConvertImageJob.perform_now(pdf_resource.id)

    image_resource.reload
    pdf_resource.reload

    # Test image resource
    assert image_resource.converted_single_file?, "Image should use single file conversion"
    assert !image_resource.converted_pages?, "Image should not have multi-page conversion"
    assert_equal :single_file, image_resource.iiif_conversion, "Image should have :single_file conversion type"

    # Test PDF resource
    assert pdf_resource.converted_pages?, "PDF should have multi-page conversion"
    assert !pdf_resource.converted_single_file?, "PDF should not use single file conversion"
    assert_equal :multi_page, pdf_resource.iiif_conversion, "PDF should have :multi_page conversion type"
  end

  # Test 5: Retry on file not uploaded error (backwards compatible)
  test "retries on FileNotUploadedError" do
    resource = Resource.create!(
      project: @project,
      name: "Test Resource"
    )

    # Attach content but mark as not uploaded
    image_path = Rails.root.join("test/fixtures/files/sample_image.jpg")
    resource.content.attach(
      io: File.open(image_path),
      filename: "sample_image.jpg",
      content_type: "image/jpeg"
    )

    resource.define_singleton_method(:content_uploaded?) { false }
    original_find = Resource.method(:find)
    Resource.define_singleton_method(:find) do |id|
      id == resource.id ? resource : original_find.call(id)
    end

    # The job should raise FileNotUploadedError which will be retried
    # For this test, we'll just verify the error is raised
    begin
      assert_raises Exceptions::FileNotUploadedError do
        ConvertImageJob.new.send(:perform, resource.id)
      end
    ensure
      Resource.define_singleton_method(:find, original_find)
    end
  end

  # Test 6: Handles empty/invalid PDFs gracefully
  test "handles empty PDF without crashing job" do
    resource = Resource.create!(
      project: @project,
      name: "Empty PDF"
    )

    # Attach an empty or invalid PDF
    empty_pdf_path = Rails.root.join("test/fixtures/files/empty.pdf")
    resource.content.attach(
      io: File.open(empty_pdf_path),
      filename: "empty.pdf",
      content_type: "application/pdf"
    )

    # Job should not raise an error, just log it
    assert_nothing_raised do
      ConvertImageJob.perform_now(resource.id)
    end

    resource.reload
    
    # Should not have attachments
    assert !resource.content_converted.attached?
    assert !resource.content_converted_pages.attached?
  end
end
