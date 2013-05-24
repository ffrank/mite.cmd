module MiteCmd
  class CompletionTable
    attr_reader :path

    def initialize(path, values = nil)
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
      ['0:05', '0:05+', '0:15', '0:15+', '0:30', '0:30+', '1:00', '1:00+'].map(&:quote)
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
      {
        0 => project_names_from_api,
        1 => service_names_from_api,
        2 => durations,
        3 => notes_from_api
      }
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
