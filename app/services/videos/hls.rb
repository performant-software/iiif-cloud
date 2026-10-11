require 'open3'

module Videos
  class Hls
    SEGMENT_SECONDS = 6

    PRESET = 'medium'

    # x264 buffers this many frames ahead for rate control, which dominates memory at high resolutions. The medium
    # preset's default is 40; halving it costs a little quality at the same bitrate.
    RC_LOOKAHEAD = 20

    # Each decoder and encoder thread buffers its own frames, so capping threads lowers peak memory at the cost of
    # speed. Set FFMPEG_THREADS=0 to let ffmpeg pick based on the host's cores.
    DEFAULT_THREADS = 2

    MASTER_PLAYLIST = 'master.m3u8'

    VARIANT_MASTER_PLAYLIST = 'variant.m3u8'

    RENDITIONS = [
      { size: 240,  video_bitrate: '400k',   maxrate: '428k',   bufsize: '600k',   audio_bitrate: '64k' },
      { size: 360,  video_bitrate: '800k',   maxrate: '856k',   bufsize: '1200k',  audio_bitrate: '96k' },
      { size: 480,  video_bitrate: '1400k',  maxrate: '1498k',  bufsize: '2100k',  audio_bitrate: '128k' },
      { size: 720,  video_bitrate: '2800k',  maxrate: '2996k',  bufsize: '4200k',  audio_bitrate: '128k' },
      { size: 1080, video_bitrate: '5000k',  maxrate: '5350k',  bufsize: '7500k',  audio_bitrate: '192k' },
      { size: 1440, video_bitrate: '9000k',  maxrate: '9630k',  bufsize: '13500k', audio_bitrate: '192k' },
      { size: 2160, video_bitrate: '16000k', maxrate: '17120k', bufsize: '24000k', audio_bitrate: '192k' }
    ].freeze

    CONTENT_TYPE_PLAYLIST = 'application/vnd.apple.mpegurl'
    CONTENT_TYPE_SEGMENT = 'video/mp2t'

    # Players fetch the segment list once, so signed segment URLs must outlast a full viewing session
    SEGMENT_URL_EXPIRES_IN = 12.hours

    def self.probe(path)
      args = ['ffprobe', '-v', 'error', '-print_format', 'json', '-show_streams', path]
      stdout, stderr, status = Open3.capture3(*args)

      raise Exceptions::VideoProbeError, "ffprobe failed: #{stderr}" unless status.success?

      JSON.parse(stdout)
    rescue Errno::ENOENT
      raise Exceptions::VideoProbeError, 'ffprobe is not installed'
    rescue JSON::ParserError => e
      raise Exceptions::VideoProbeError, "Unable to parse ffprobe output: #{e.message}"
    end

    # Returns the short side of the video frame. Using the short side also makes rotation metadata irrelevant, since
    # ffprobe reports the stored (unrotated) dimensions.
    def self.source_size(streams)
      stream = streams.find { |s| s['codec_type'] == 'video' }
      return nil unless stream

      dimensions = stream.values_at('width', 'height').map(&:to_i).select(&:positive?)
      dimensions.min
    end

    def self.audio?(streams)
      streams.any? { |stream| stream['codec_type'] == 'audio' }
    end

    def self.renditions_for(size)
      return RENDITIONS.first(1) if size.nil? || size <= 0

      applicable = RENDITIONS.select { |rendition| rendition[:size] <= size }
      applicable.presence || RENDITIONS.first(1)
    end

    # Encodes one rendition at a time so only a single x264 encoder is in memory, then combines each rendition's
    # variant entry into the master playlist.
    def self.transcode(source_path, output_dir, renditions, audio: true)
      variants = renditions.each_with_index.map do |rendition, index|
        stream_dir = File.join(output_dir, "stream_#{index}")
        FileUtils.mkdir_p(stream_dir)

        _stdout, stderr, status = Open3.capture3(*command(source_path, stream_dir, rendition, audio:))

        raise Exceptions::VideoTranscodingError, "ffmpeg failed: #{stderr}" unless status.success?

        variant_entry(stream_dir, "stream_#{index}")
      end

      master_path = File.join(output_dir, MASTER_PLAYLIST)
      File.write(master_path, "#EXTM3U\n#EXT-X-VERSION:6\n#{variants.join("\n")}")

      master_path
    rescue Errno::ENOENT
      raise Exceptions::VideoTranscodingError, 'ffmpeg is not installed'
    end

    def self.command(source_path, stream_dir, rendition, audio: true)
      args = ['ffmpeg', '-y']

      # Before -i so it limits the decoder
      args += ['-threads', threads]
      args += ['-i', source_path]

      args += ['-map', '0:v:0']
      args += ['-vf', scale_filter(rendition[:size])]
      args += ['-c:v', 'libx264']
      args += ['-b:v', rendition[:video_bitrate]]
      args += ['-maxrate', rendition[:maxrate]]
      args += ['-bufsize', rendition[:bufsize]]

      if audio
        args += %w[-map 0:a:0]
        args += ['-c:a', 'aac']
        args += ['-b:a', rendition[:audio_bitrate]]
        args += ['-ac', '2']
      end

      args += ['-preset', PRESET]
      args += ['-rc-lookahead', RC_LOOKAHEAD.to_s]
      args += ['-threads', threads]
      args += %w[-pix_fmt yuv420p]

      args += %w[-sc_threshold 0]
      args += ['-force_key_frames', "expr:gte(t,n_forced*#{SEGMENT_SECONDS})"]

      args += %w[-f hls]
      args += ['-hls_time', SEGMENT_SECONDS.to_s]
      args += %w[-hls_playlist_type vod]
      args += %w[-hls_flags independent_segments]
      args += %w[-hls_segment_type mpegts]
      args += ['-hls_segment_filename', File.join(stream_dir, 'segment_%03d.ts')]
      # ffmpeg measures each variant's bandwidth, resolution and codecs, so let it write a single-variant master that
      # variant_entry merges into the real one
      args += ['-master_pl_name', VARIANT_MASTER_PLAYLIST]
      args << File.join(stream_dir, 'playlist.m3u8')

      args
    end

    # Returns the stream info tag and URI from a rendition's single-variant master, with the URI made relative to the
    # HLS root. Removes that master so it isn't uploaded.
    def self.variant_entry(stream_dir, stream_name)
      path = File.join(stream_dir, VARIANT_MASTER_PLAYLIST)
      raise Exceptions::VideoTranscodingError, 'Variant playlist was not created' unless File.exist?(path)

      lines = File.readlines(path, chomp: true)
      File.delete(path)

      index = lines.index { |line| line.start_with?('#EXT-X-STREAM-INF:') }
      uri = index && lines[index + 1]
      raise Exceptions::VideoTranscodingError, 'Variant playlist is missing stream info' if uri.blank?

      "#{lines[index]}\n#{stream_name}/#{uri}\n"
    end

    def self.threads
      ENV.fetch('FFMPEG_THREADS', DEFAULT_THREADS).to_s
    end

    def self.scale_filter(size)
      "scale=w='if(gte(iw,ih),-2,#{size})':h='if(gte(iw,ih),#{size},-2)'"
    end

    def self.content_type_for(path)
      File.extname(path) == '.m3u8' ? CONTENT_TYPE_PLAYLIST : CONTENT_TYPE_SEGMENT
    end
  end
end
