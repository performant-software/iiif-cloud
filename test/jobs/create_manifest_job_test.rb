require "test_helper"
require "minitest/mock"

class CreateManifestJobTest < ActiveJob::TestCase
  test "analyzing a video doesn't reprocess its content" do
    resource = Resource.create!(project: projects(:one), name: "Test Video")
    resource.content.attach(io: StringIO.new("video"), filename: "video.mp4", content_type: "video/mp4")
    clear_enqueued_jobs

    Iiif::Manifest.stub(:create_for_resource, {}) do
      CreateManifestJob.perform_now(resource.id)
    end

    assert Resource.find(resource.id).content.blob.analyzed?
    assert_no_enqueued_jobs only: [ProcessVideoJob, ConvertImageJob, ExtractExifJob]
  end
end
