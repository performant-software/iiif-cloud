require 'pathname'

module Videos
  class Playlist
    URI_ATTRIBUTE = /URI="([^"]+)"/

    ABSOLUTE_URI = %r{\A[a-z][a-z0-9+.\-]*:}i

    PLAYLIST_EXTENSION = '.m3u8'

    # Replaces each media URI in the passed playlist with the value returned by the block. The block receives the URI's
    # path relative to the HLS root. Nested playlists and absolute URIs are left as-is, so players request nested
    # playlists relative to the current playlist URL.
    def self.rewrite(playlist, directory, &block)
      playlist.each_line.map do |line|
        stripped = line.strip

        if stripped.empty?
          line
        elsif stripped.start_with?('#')
          line.gsub(URI_ATTRIBUTE) { "URI=\"#{replace(Regexp.last_match(1), directory, &block)}\"" }
        else
          line.sub(stripped) { replace(stripped, directory, &block) }
        end
      end.join
    end

    def self.replace(uri, directory)
      return uri if uri.match?(ABSOLUTE_URI)
      return uri if File.extname(uri) == PLAYLIST_EXTENSION

      path = Pathname.new(directory).join(uri).cleanpath.to_s
      raise ArgumentError, "Playlist URI is outside of the HLS directory: #{uri}" if path.start_with?('..', '/')

      yield path
    end
  end
end
