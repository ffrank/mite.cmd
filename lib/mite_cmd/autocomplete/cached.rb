require 'mite_cmd/autocomplete'

class MiteCmd::Autocomplete::Cached < MiteCmd::Autocomplete
  LOOKASIDE_CACHE = File.expand_path('~/.mite.autocomplete-lookaside-buffer')

  MARKER = '__MITE_CMD_RESULT_FOR__'

  def current_buffer
    if ! File.exists?(LOOKASIDE_CACHE)
      return []
    end
    IO.readlines(LOOKASIDE_CACHE).map(&:chomp)
  end

  def refresh_buffer(lines)
    # first line always holds the marker
    output = [ "#{MARKER}#{current_word}" ]

    # only one suggestion? The shell will complete this. DON'T cache!
    if lines.length > 1
      output += lines
    end

    File.open(LOOKASIDE_CACHE, "w") do |file|
      file.write output * "\n"
    end
  end

  def suggestions
    result = current_buffer

    if result.empty?
      result = super
    else
      if result[0].sub(/#{MARKER}/, '') != current_word
        # cache miss
        result = super
      else
        # cache hit: just remove the marker line
        result.slice!(0)
      end
    end

    result.select! { |suggestion| suggestion =~ /^#{current_word}/ }

    refresh_buffer(result)

    result
  end
end
