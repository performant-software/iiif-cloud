require 'open3'

module Videos
  class Hls
    SEGMENT_SECONDS = 6

    PRESET = 'medium'

    MASTER_PLAYLIST = 'master.m3u8'

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

    def self.transcode(source_path, output_dir, renditions, audio: true)
      renditions.each_index do |index|
        FileUtils.mkdir_p(File.join(output_dir, "stream_#{index}"))
      end

      stdout, stderr, status = Open3.capture3(*command(source_path, output_dir, renditions, audio:))

      raise Exceptions::VideoTranscodingError, "ffmpeg failed: #{stderr}" unless status.success?

      master_path = File.join(output_dir, MASTER_PLAYLIST)
      raise Exceptions::VideoTranscodingError, 'Master playlist was not created' unless File.exist?(master_path)

      master_path
    rescue Errno::ENOENT
      raise Exceptions::VideoTranscodingError, 'ffmpeg is not installed'
    end

    def self.command(source_path, output_dir, renditions, audio: true)
      args = ['ffmpeg', '-y', '-i', source_path]

      splits = renditions.each_index.map { |index| "[v#{index}]" }.join
      filters = ["[0:v]split=#{renditions.size}#{splits}"]
      renditions.each_with_index do |rendition, index|
        filters << "[v#{index}]#{scale_filter(rendition[:size])}[v#{index}out]"
      end
      args += ['-filter_complex', filters.join('; ')]

      renditions.each_with_index do |rendition, index|
        args += ['-map', "[v#{index}out]"]
        args += ["-c:v:#{index}", 'libx264']
        args += ["-b:v:#{index}", rendition[:video_bitrate]]
        args += ["-maxrate:v:#{index}", rendition[:maxrate]]
        args += ["-bufsize:v:#{index}", rendition[:bufsize]]
      end

      if audio
        renditions.each_with_index do |rendition, index|
          args += %w[-map a:0]
          args += ["-c:a:#{index}", 'aac']
          args += ["-b:a:#{index}", rendition[:audio_bitrate]]
          args += ["-ac:a:#{index}", '2']
        end
      end

      args += ['-preset', PRESET]
      args += %w[-pix_fmt yuv420p]

      args += %w[-sc_threshold 0]
      args += ['-force_key_frames', "expr:gte(t,n_forced*#{SEGMENT_SECONDS})"]

      args += %w[-f hls]
      args += ['-hls_time', SEGMENT_SECONDS.to_s]
      args += %w[-hls_playlist_type vod]
      args += %w[-hls_flags independent_segments]
      args += %w[-hls_segment_type mpegts]
      args += ['-hls_segment_filename', File.join(output_dir, 'stream_%v', 'segment_%03d.ts')]
      args += ['-master_pl_name', MASTER_PLAYLIST]
      args += ['-var_stream_map', variant_map(renditions, audio:)]
      args << File.join(output_dir, 'stream_%v', 'playlist.m3u8')

      args
    end

    def self.scale_filter(size)
      "scale=w='if(gte(iw,ih),-2,#{size})':h='if(gte(iw,ih),#{size},-2)'"
    end

    def self.variant_map(renditions, audio: true)
      renditions.each_index.map do |index|
        audio ? "v:#{index},a:#{index}" : "v:#{index}"
      end.join(' ')
    end

    def self.content_type_for(path)
      File.extname(path) == '.m3u8' ? CONTENT_TYPE_PLAYLIST : CONTENT_TYPE_SEGMENT
    end
  end
end
