require "test_helper"
require "minitest/mock"

class ProcessVideoJobTest < ActiveJob::TestCase
  setup do
    @service = ActiveStorage::Blob.service
    @resource = Resource.create!(project: projects(:one), name: "Test Video", storage_key: "videos")
    @resource.content.attach(io: StringIO.new("video"), filename: "video.mp4", content_type: "video/mp4")
    @prefix = ProcessVideoJob.hls_prefix(@resource)
  end

  test "uploading a ladder removes renditions from the previous ladder" do
    @service.upload("#{@prefix}/master.m3u8", StringIO.new("old master"))
    @service.upload("#{@prefix}/stream_0/playlist.m3u8", StringIO.new("old playlist"))
    @service.upload("#{@prefix}/stream_4/playlist.m3u8", StringIO.new("old playlist"))
    @service.upload("#{@prefix}/stream_4/segment_000.ts", StringIO.new("old segment"))

    Dir.mktmpdir do |output_dir|
      FileUtils.mkdir_p(File.join(output_dir, "stream_0"))
      File.write(File.join(output_dir, "master.m3u8"), "new master")
      File.write(File.join(output_dir, "stream_0", "playlist.m3u8"), "new playlist")

      ProcessVideoJob.new.send(:upload_ladder, @resource, output_dir)
    end

    assert_equal "new master", @service.download("#{@prefix}/master.m3u8")
    assert_equal "new playlist", @service.download("#{@prefix}/stream_0/playlist.m3u8")
    assert_not @service.exist?("#{@prefix}/stream_4/playlist.m3u8")
    assert_not @service.exist?("#{@prefix}/stream_4/segment_000.ts")
  end

  test "rebuilds the manifest before transcoding when the existing manifest uses HLS" do
    @resource.update_columns(conversion_status: "succeeded")
    clear_enqueued_jobs

    assert_manifest_jobs_before_transcoding 1
  end

  test "does not rebuild the manifest before transcoding when the existing manifest doesn't use HLS" do
    clear_enqueued_jobs

    assert_manifest_jobs_before_transcoding 0
  end

  private

  def assert_manifest_jobs_before_transcoding(count)
    probe = lambda do |_path|
      assert_enqueued_jobs count, only: CreateManifestJob
      raise "stop before transcoding"
    end

    Videos::Hls.stub(:probe, probe) do
      assert_raises(RuntimeError) { ProcessVideoJob.perform_now(@resource.id) }
    end
  end
end
