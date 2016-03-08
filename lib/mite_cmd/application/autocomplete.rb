require 'mite_cmd/autocomplete/cached.rb'

module MiteCmd
  module Application::AutoComplete

    def auto_complete(arguments)
      autocomplete = MiteCmd::Autocomplete::Cached.new(MiteCmd.calling_script)
      #autocomplete.completion_table = MiteCmd::CompletionTable.new(cache_file)
      result = autocomplete.suggestions
      if autocomplete.user_supplied?
        if MiteCmd.autocomplete_always_quote
          result.map!(&:quote)
        else
          result.map!(&:quote_if_spaced)
        end
      end
      result.each { |s| tell s }
    end

    def rebuild_cache(arguments)
      rebuild_completion_table
      tell 'The rebuilding of the cache has been done, Master. Your wish is my command.'
    end

    def rebuild_completion_table
      MiteCmd::CompletionTable.new.rebuild
    end

    def try_to_setup_bash_completion
      bash_code = "\n\n#{MiteCmd::BASH_COMPLETION}"

      ['~/.bash_completion', '~/.bash_profile', '~/.bash_login', '~/.bashrc'].each do |file|
        bash_config_file = File.expand_path file
        next unless File.file?(bash_config_file)
        unless File.read(bash_config_file) =~ /#{bash_code}/
          File.open(bash_config_file, 'a') do |f|
            f.puts bash_code
          end
          return true
        else
          return true
        end
      end
      return false
    end

  end
end
