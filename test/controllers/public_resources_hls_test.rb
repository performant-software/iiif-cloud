require "test_helper"

class PublicResourcesHlsTest < ActionDispatch::IntegrationTest
  setup do
    @resource = Resource.create!(project: projects(:one), name: "Test Video", storage_key: SecureRandom.uuid)
    @resource.content.attach(io: StringIO.new("video"), filename: "video.mp4", content_type: "video/mp4")
    @resource.update_columns(conversion_status: "succeeded", hls_identifier: @resource.content.key)

    @prefix = ProcessVideoJob.hls_prefix(@resource)
    service = ActiveStorage::Blob.service
    service.upload("#{@prefix}/master.m3u8", StringIO.new("#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=528000\nstream_0/playlist.m3u8\n"))
    service.upload("#{@prefix}/stream_0/playlist.m3u8", StringIO.new("#EXTM3U\n#EXTINF:6.000000,\nsegment_000.ts\n#EXT-X-ENDLIST\n"))
    service.upload("#{@prefix}/stream_0/segment_000.ts", StringIO.new("segment"))
  end

  test "serves the master playlist without authentication" do
    get "/public/resources/#{@resource.uuid}/hls/master.m3u8"

    assert_response :ok
    assert_equal Videos::Hls::CONTENT_TYPE_PLAYLIST, response.media_type
    assert_includes response.body, "\nstream_0/playlist.m3u8\n"
  end

  test "serves variant playlists with signed segment URLs" do
    get "/public/resources/#{@resource.uuid}/hls/stream_0/playlist.m3u8"

    assert_response :ok
    assert_equal "no-store", response.headers["Cache-Control"]

    segment_url = response.body.lines.map(&:strip).find { |line| line.start_with?("http") }
    assert segment_url, "Expected a signed segment URL in #{response.body.inspect}"

    get segment_url
    assert_response :ok
    assert_equal "segment", response.body
  end

  test "returns not found for paths other than playlists" do
    get "/public/resources/#{@resource.uuid}/hls/stream_0/segment_000.ts"
    assert_response :not_found

    get "/public/resources/#{@resource.uuid}/hls/..%2Fvideo.m3u8"
    assert_response :not_found
  end

  test "returns not found until transcoding succeeds" do
    @resource.update_columns(conversion_status: "processing")

    get "/public/resources/#{@resource.uuid}/hls/master.m3u8"

    assert_response :not_found
  end

  test "returns not found once the content is replaced" do
    Resource.find(@resource.id).content.attach(io: StringIO.new("new video"), filename: "new.mp4", content_type: "video/mp4")

    get "/public/resources/#{@resource.uuid}/hls/master.m3u8"

    assert_response :not_found
  end

  test "manifest references the master playlist once transcoding succeeds" do
    body = JSON.parse(Iiif::Manifest.create_for_resource(@resource)).dig("items", 0, "items", 0, "items", 0, "body")

    assert_equal "#{ENV['HOSTNAME']}/public/resources/#{@resource.uuid}/hls/master.m3u8", body["id"]
    assert_equal Videos::Hls::CONTENT_TYPE_PLAYLIST, body["format"]
  end

  test "manifest references the original file until transcoding succeeds" do
    @resource.update_columns(conversion_status: "failed")

    body = JSON.parse(Iiif::Manifest.create_for_resource(@resource)).dig("items", 0, "items", 0, "items", 0, "body")

    assert_equal @resource.content_url, body["id"]
    assert_equal "video/mp4", body["format"]
  end

  test "returns not found for missing playlists" do
    get "/public/resources/#{@resource.uuid}/hls/stream_9/playlist.m3u8"

    assert_response :not_found
  end
end
