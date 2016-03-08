require 'shellwords'

module MiteCmd
  class Autocomplete
    include Shellwords

    CACHE_FILE = File.expand_path('~/.mite.cache')
    
    attr_reader :calling_script

    def completion_table
      @completion_table ||= MiteCmd::CompletionTable.new(CACHE_FILE)
    end
    
    def initialize(calling_script)
      @calling_script = calling_script
    end
    
    def bash_line
      ENV['COMP_LINE'].to_s
    end
  
    def argument_string
      bash_line.sub(/^(.*)#{File.basename calling_script}\s*/, '').close_unmatched_quotes
    end
  
    def partial_argument_string
      bash_line[0..cursor_position+1].sub(/^(.*)#{File.basename calling_script}\s*/, '').close_unmatched_quotes
    end
  
    def current_word
      return nil if argument_string =~ /\s$/ && bash_line.length == cursor_position
      shellwords(partial_argument_string).last
    end
  
    def current_argument_index
      return args.size if argument_string =~ /\s$/ && bash_line.length == cursor_position
      args.index(current_word) || 0
    end
  
    def cursor_position
      ENV['COMP_POINT'].to_i
    end
  
    def args
      shellwords(argument_string)
    end
  
    def suggestions
      if current_argument_index == 0
        MiteCmd::Application::Main.command_list
      elsif args.size > 0 and args[0] == "add" || args[0] == "preview"
        completion_table[current_argument_index-1] ? completion_table[current_argument_index-1].select {|s| s =~ /^#{current_word}/} : []
      else
        []
      end
    end

    def user_supplied?
      args.size > 1 and current_argument_index > 1 and args[0] == "add" || args[0] == "preview"
    end
  end
end
