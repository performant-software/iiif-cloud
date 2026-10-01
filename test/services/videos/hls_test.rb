require "test_helper"

class Videos::HlsTest < ActiveSupport::TestCase
  test "source size is the short side of the video frame" do
    landscape = [{ "codec_type" => "video", "width" => 3840, "height" => 2160 }]
    portrait = [{ "codec_type" => "video", "width" => 1080, "height" => 1920 }]

    assert_equal 2160, Videos::Hls.source_size(landscape)
    assert_equal 1080, Videos::Hls.source_size(portrait)
  end

  test "source size ignores audio streams and missing dimensions" do
    streams = [
      { "codec_type" => "audio" },
      { "codec_type" => "video", "width" => 1280 }
    ]

    assert_equal 1280, Videos::Hls.source_size(streams)
    assert_nil Videos::Hls.source_size([{ "codec_type" => "audio" }])
    assert_nil Videos::Hls.source_size([{ "codec_type" => "video" }])
  end

  test "4K sources get the full ladder" do
    sizes = Videos::Hls.renditions_for(2160).map { |rendition| rendition[:size] }

    assert_equal [240, 360, 480, 720, 1080, 1440, 2160], sizes
  end

  test "sources between rungs stop at the rung below" do
    sizes = Videos::Hls.renditions_for(1600).map { |rendition| rendition[:size] }

    assert_equal [240, 360, 480, 720, 1080, 1440], sizes
  end

  test "portrait sources get the same ladder as landscape sources" do
    portrait = [{ "codec_type" => "video", "width" => 1080, "height" => 1920 }]
    landscape = [{ "codec_type" => "video", "width" => 1920, "height" => 1080 }]

    assert_equal Videos::Hls.renditions_for(Videos::Hls.source_size(landscape)),
                 Videos::Hls.renditions_for(Videos::Hls.source_size(portrait))
  end

  test "tiny or unknown sources get the smallest rung" do
    assert_equal [240], Videos::Hls.renditions_for(144).map { |rendition| rendition[:size] }
    assert_equal [240], Videos::Hls.renditions_for(nil).map { |rendition| rendition[:size] }
  end

  test "transcoding a portrait video scales the short side" do
    skip "ffmpeg is not installed" unless system("which ffmpeg > /dev/null 2>&1")

    Dir.mktmpdir do |dir|
      source = File.join(dir, "portrait.mp4")
      system("ffmpeg", "-v", "error", "-y", "-f", "lavfi", "-i", "testsrc=size=480x854:rate=30", "-t", "1", source,
             exception: true)

      renditions = Videos::Hls.renditions_for(Videos::Hls.source_size(Videos::Hls.probe(source)["streams"]))
      output_dir = File.join(dir, "hls")
      Videos::Hls.transcode(source, output_dir, renditions, audio: false)

      resolutions = File.read(File.join(output_dir, Videos::Hls::MASTER_PLAYLIST)).scan(/RESOLUTION=(\d+x\d+)/).flatten

      # The long side is rounded to an even number (427 -> 428)
      assert_equal %w[240x428 360x640 480x854], resolutions
    end
  end
end
