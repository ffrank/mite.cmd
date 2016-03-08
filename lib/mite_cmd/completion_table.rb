module MiteCmd
  class CompletionTable
    attr_reader :path

    DEFAULT_CACHE_FILE=File.expand_path('~/.mite.cache')

    def initialize(path = DEFAULT_CACHE_FILE, values = nil)
      @path = path
      @values = values
    end

    def [](key)
      values[key]
    end

    # Rebuilds the cache file with updated values from Mite
    def rebuild
      delete_cache_file
      write(values)
      return values
    end

    def values
      @values ||= values_from_disk || values_from_api
    end

    private

    def delete_cache_file
      File.delete(path) if File.exist?(path)
    end

    def durations
      ['0:05', '0:15', '0:30', '1:00', '1:30'].map(&:quote)
    end

    def notes_from_api
      @notes ||= (Mite::TimeEntry.all || []).map(&:note).compact
    end

    def project_names_from_api
      @project_names ||= (Mite::Project.all || []).map(&:name)
    end

    def service_names_from_api
      @service_names ||= (Mite::Service.all || []).map(&:name)
    end

    def values_from_api
      result = {
        0 => durations,
        1 => project_names_from_api,
        2 => service_names_from_api,
      }
      if MiteCmd.autocomplete_notes
        result[3] = notes_from_api
      end
      result
    end

    def values_from_disk
      if File.exist?(path)
        Marshal.load File.read(path)
      else
        nil
      end
    end

    def write(values)
      File.open(path, 'w') { |f| Marshal.dump(values, f) }
      File.chmod(0600, path)
    end
  end
end
