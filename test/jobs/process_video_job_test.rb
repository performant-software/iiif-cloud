require "test_helper"
require "minitest/mock"

class ProcessVideoJobTest < ActiveJob::TestCase
  setup do
    @service = ActiveStorage::Blob.service
    @resource = Resource.create!(project: projects(:one), name: "Test Video", storage_key: "videos")
    @resource.content.attach(io: StringIO.new("video"), filename: "video.mp4", content_type: "video/mp4")
    @prefix = ProcessVideoJob.hls_prefix(@resource, @resource.content.key)
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

      ProcessVideoJob.new.send(:upload_ladder, @prefix, output_dir)
    end

    assert_equal "new master", @service.download("#{@prefix}/master.m3u8")
    assert_equal "new playlist", @service.download("#{@prefix}/stream_0/playlist.m3u8")
    assert_not @service.exist?("#{@prefix}/stream_4/playlist.m3u8")
    assert_not @service.exist?("#{@prefix}/stream_4/segment_000.ts")
  end

  test "rebuilds the manifest before transcoding when the existing manifest uses HLS" do
    @resource.update_columns(conversion_status: "succeeded", hls_identifier: @resource.content.key)
    clear_enqueued_jobs

    assert_manifest_jobs_before_transcoding 1
  end

  test "does not rebuild the manifest before transcoding when the existing manifest doesn't use HLS" do
    clear_enqueued_jobs

    assert_manifest_jobs_before_transcoding 0
  end

  test "publishes the ladder and deletes the previous content's ladder" do
    previous_prefix = ProcessVideoJob.hls_prefix(@resource, "previous")
    @service.upload("#{previous_prefix}/master.m3u8", StringIO.new("previous master"))
    @resource.update_columns(hls_identifier: "previous")

    perform_enqueued_jobs(only: DeleteHlsJob) do
      transcode
    end

    @resource.reload
    assert_equal "succeeded", @resource.conversion_status
    assert_equal @resource.content.key, @resource.hls_identifier
    assert @resource.hls?
    assert_equal "master", @service.download("#{@prefix}/master.m3u8")
    assert_not @service.exist?("#{previous_prefix}/master.m3u8")
  end

  test "discards the ladder when the content is replaced during transcoding" do
    replacement_prefix = nil

    replace_content = lambda do |_path, output_dir, _renditions, **|
      resource = Resource.find(@resource.id)
      resource.content.attach(io: StringIO.new("new video"), filename: "new.mp4", content_type: "video/mp4")
      replacement_prefix = ProcessVideoJob.hls_prefix(resource, resource.content.key)
      @service.upload("#{replacement_prefix}/master.m3u8", StringIO.new("replacement master"))
      resource.update_columns(conversion_status: "succeeded", hls_identifier: resource.content.key)

      File.write(File.join(output_dir, "master.m3u8"), "master")
    end

    transcode(replace_content)

    resource = Resource.find(@resource.id)
    assert_equal "succeeded", resource.conversion_status
    assert_equal resource.content.key, resource.hls_identifier
    assert resource.hls?
    assert_equal "replacement master", @service.download("#{replacement_prefix}/master.m3u8")
    assert_not @service.exist?("#{@prefix}/master.m3u8"), "The replaced content's ladder should be discarded"
  end

  test "does not record a failure when the content is replaced during transcoding" do
    replace_content_and_fail = lambda do |*, **|
      resource = Resource.find(@resource.id)
      resource.content.attach(io: StringIO.new("new video"), filename: "new.mp4", content_type: "video/mp4")
      raise "ffmpeg failed"
    end

    assert_nothing_raised { transcode(replace_content_and_fail) }

    assert_equal "pending", @resource.reload.conversion_status
    assert_enqueued_with job: DeleteHlsJob, args: [@prefix]
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

  def transcode(ffmpeg = nil)
    ffmpeg ||= lambda do |_path, output_dir, _renditions, **|
      File.write(File.join(output_dir, "master.m3u8"), "master")
    end

    Videos::Hls.stub(:probe, { "streams" => [] }) do
      Videos::Hls.stub(:transcode, ffmpeg) do
        ProcessVideoJob.perform_now(@resource.id)
      end
    end
  end
end
