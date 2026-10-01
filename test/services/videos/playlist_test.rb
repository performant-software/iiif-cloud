require "test_helper"

class Videos::PlaylistTest < ActiveSupport::TestCase
  test "leaves nested playlist URIs relative" do
    playlist = <<~M3U8
      #EXTM3U
      #EXT-X-VERSION:3
      #EXT-X-STREAM-INF:BANDWIDTH=528000,RESOLUTION=426x240
      stream_0/playlist.m3u8
    M3U8

    rewritten = Videos::Playlist.rewrite(playlist, ".") { |path| "signed://#{path}" }

    assert_equal playlist, rewritten
  end

  test "replaces segment URIs relative to the playlist directory" do
    playlist = <<~M3U8
      #EXTM3U
      #EXT-X-TARGETDURATION:6
      #EXTINF:6.000000,
      segment_000.ts
      #EXTINF:4.200000,
      segment_001.ts
      #EXT-X-ENDLIST
    M3U8

    rewritten = Videos::Playlist.rewrite(playlist, "stream_1") { |path| "signed://#{path}?sig=a&b=c" }

    assert_equal <<~M3U8, rewritten
      #EXTM3U
      #EXT-X-TARGETDURATION:6
      #EXTINF:6.000000,
      signed://stream_1/segment_000.ts?sig=a&b=c
      #EXTINF:4.200000,
      signed://stream_1/segment_001.ts?sig=a&b=c
      #EXT-X-ENDLIST
    M3U8
  end

  test "replaces URI attributes on tags" do
    playlist = %(#EXT-X-MAP:URI="init.mp4"\n)

    rewritten = Videos::Playlist.rewrite(playlist, "stream_0") { |path| "signed://#{path}" }

    assert_equal %(#EXT-X-MAP:URI="signed://stream_0/init.mp4"\n), rewritten
  end

  test "leaves absolute URIs unchanged" do
    playlist = "https://example.com/segment_000.ts\n"

    assert_equal playlist, Videos::Playlist.rewrite(playlist, "stream_0") { |path| "signed://#{path}" }
  end

  test "rejects URIs outside of the HLS directory" do
    assert_raises ArgumentError do
      Videos::Playlist.rewrite("../../original.mp4\n", "stream_0") { |path| path }
    end
  end
end
