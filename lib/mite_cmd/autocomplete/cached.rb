require 'mite_cmd/autocomplete'

class MiteCmd::Autocomplete::Cached < MiteCmd::Autocomplete
  LOOKASIDE_CACHE = File.expand_path('~/.mite.autocomplete-lookaside-buffer')

  EMPTY_MARKER = '__MITE_CMD_NO_RESULT_FOR__'

  def current_buffer
    if ! File.exists?(LOOKASIDE_CACHE)
      return []
    end
    IO.readlines(LOOKASIDE_CACHE).map(&:chomp)
  end

  def refresh_buffer(lines)
    # only one suggestion? The shell will complete this. DON'T cache!
    if lines.length == 1
      output = []
    else
      output = lines
    end

    File.open(LOOKASIDE_CACHE, "w") do |file|
      file.write output * "\n"
    end
  end

  def suggestions
    result = current_buffer

    if result.length == 1 and result[0] =~ /^#{EMPTY_MARKER}/
      if result[0].sub(/#{EMPTY_MARKER}/, '') == current_word
        # current query yields no result: stop
        return []
      else
        # previous query had no result, but input changed: remove mark
        result = []
      end
    end

    if result.empty?
      result = super
    end

    result.select! { |suggestion| suggestion =~ /^#{current_word}/ }

    # no result after full lookup: mark as empty
    if result.empty?
      mark = "#{EMPTY_MARKER}#{current_word}"
      refresh_buffer([mark])
      return []
    end

    refresh_buffer(result)

    result
  end
end
