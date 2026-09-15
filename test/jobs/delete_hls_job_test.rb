require "test_helper"

class DeleteHlsJobTest < ActiveJob::TestCase
  setup do
    @project = projects(:one)
    @service = ActiveStorage::Blob.service
  end

  test "destroying a video resource deletes its HLS files" do
    resource = create_resource("video/mp4", storage_key: "shared")
    other = create_resource("video/mp4", storage_key: "shared")
    [resource, other].each { |r| upload_ladder(r) }

    perform_enqueued_jobs(only: DeleteHlsJob) do
      Resource.find(resource.id).destroy!
    end

    assert_not @service.exist?("#{ProcessVideoJob.hls_prefix(resource, resource.content.key)}/master.m3u8")
    assert_not @service.exist?("#{ProcessVideoJob.hls_prefix(resource, resource.content.key)}/stream_0/segment_000.ts")
    assert @service.exist?("#{ProcessVideoJob.hls_prefix(other, other.content.key)}/master.m3u8"), "Other resources' HLS files should remain"
  end

  test "destroying a video resource without a storage key deletes its HLS files" do
    resource = create_resource("video/mp4")
    upload_ladder(resource)

    perform_enqueued_jobs(only: DeleteHlsJob) do
      Resource.find(resource.id).destroy!
    end

    assert_not @service.exist?("#{ProcessVideoJob.hls_prefix(resource, resource.content.key)}/master.m3u8")
  end

  test "destroying a non-video resource does not enqueue HLS deletion" do
    resource = create_resource("image/jpeg")

    assert_no_enqueued_jobs(only: DeleteHlsJob) do
      Resource.find(resource.id).destroy!
    end
  end

  test "replacing HLS content with an image deletes the previous HLS files" do
    resource = create_resource("video/mp4", storage_key: "shared")
    upload_ladder(resource)
    prefix = ProcessVideoJob.hls_prefix(resource, resource.content.key)
    resource.update_columns(conversion_status: "succeeded", hls_identifier: resource.content.key)
    clear_enqueued_jobs

    perform_enqueued_jobs(only: DeleteHlsJob) do
      Resource.find(resource.id).content.attach(io: StringIO.new("image"), filename: "image.jpg", content_type: "image/jpeg")
    end

    resource.reload
    assert_not @service.exist?("#{prefix}/master.m3u8")
    assert_nil resource.hls_identifier
    assert_equal "pending", resource.conversion_status
    assert_enqueued_jobs 1, only: CreateManifestJob
  end

  test "rejects prefixes outside of an HLS directory" do
    assert_raises ArgumentError do
      DeleteHlsJob.perform_now("shared")
    end
  end

  private

  def create_resource(content_type, storage_key: nil)
    resource = Resource.create!(project: @project, name: "Resource", storage_key: storage_key)
    resource.content.attach(io: StringIO.new("content"), filename: "file", content_type: content_type)
    resource
  end

  def upload_ladder(resource)
    prefix = ProcessVideoJob.hls_prefix(resource, resource.content.key)
    @service.upload("#{prefix}/master.m3u8", StringIO.new("#EXTM3U\n"))
    @service.upload("#{prefix}/stream_0/segment_000.ts", StringIO.new("segment"))
  end
end
