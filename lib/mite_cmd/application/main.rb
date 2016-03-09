require 'mite_cmd/application/autocomplete'
require 'mite_cmd/application/time_entries'
require 'optparse'

if RUBY_VERSION >= '1.9'
  require 'fileutils'
else
  require 'ftools'
end

module MiteCmd::Application
  class Main
    include MiteCmd::Application::AutoComplete
    include MiteCmd::Application::TimeEntries

    def initialize(arguments=[])
      option_parser.parse!(arguments)
      @arguments = arguments
      @default_attributes = {}
      MiteCmd.load_configuration! unless ['configure', 'help'].include?(arguments.first)
    end

    def run
      if @arguments.empty?
        current
      else
        dispatch(@arguments)
      end
    end

    def say(what)
      puts what
    end
    alias_method :tell, :say

    private

    def configure(arguments)
      raise MiteCmd::Exception.new('mite configure needs two arguments, the account name and the apikey') if @arguments.size < 3
      MiteCmd.load_configuration

      settings = {:account => @arguments[1], :apikey => @arguments[2]}
      settings[:autocomplete_notes] = MiteCmd.autocomplete_notes
      settings[:autocomplete_always_quote] = MiteCmd.autocomplete_always_quote
      write_configuration(settings)

      tell("Couldn't set up bash completion. I'm terribly frustrated. Maybe 'mite help' helps out.") unless try_to_setup_bash_completion
    end

    def self.method_list
      {
        'auto-complete' => :auto_complete,
        'configure' => :configure,
        'help' => :help,
        'lunch' => :stop,
        'note' => :note,
        'open' => :open,
        'pause' => :stop,
        'rebuild-cache' => :rebuild_cache,
        'start' => :start,
        'stop' => :stop,
        'add' => :create_time_entry,
        'report' => :report,
        'preview' => :prepare_time_entry,
        'delete' => :destroy_time_entry,
        'reword' => :reword_time_entry,
      }
    end

    def self.command_list
      method_list.keys
    end

    def method_for_command(command)
      self.class.method_list[command]
    end

    def dispatch(arguments)
      command, *arguments_for_command = arguments
      method = method_for_command(command)

      if command == 'preview'
        @default_attributes = { 'revenue' => 0.0 }
      end

      if method
        send(method, arguments_for_command)
      else
        help(nil)
      end
    end

    def help(arguments)
      puts <<-EOH
usage: mite <command> [arguments]

available commands:
  TODO
      EOH
    end

    def open(arguments)
      open_or_echo Mite.account_url
    end

    def open_or_echo(open_argument)
      exec "open '#{open_argument}' || echo '#{open_argument}'"
    end

    def write_configuration(config)
      File.open(File.expand_path('~/.mite.yml'), 'w') do |f|
        YAML.dump(config, f)
      end
      File.chmod(0600, File.expand_path('~/.mite.yml'))
    end

    def option_parser
      OptionParser.new do |opts|
        opts.on("-d", "--date DATE",
                "Create or report on specific day, e.g. today, yesterday, YYYY-MM-DD, ...") { |arg| @date = arg }
        opts.on("-x", "--really",
                "Confirm destructive actions such as delete") { |arg| @confirmed = arg }
      end
    end

  end
end
