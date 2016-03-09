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
      if ['configure', 'help'].include?(arguments.first)
        MiteCmd.load_configuration
      else
        MiteCmd.load_configuration! unless ['configure', 'help'].include?(arguments.first)
      end
      option_parser.parse!(arguments)

      @arguments = arguments
      @default_attributes = {}
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
      raise MiteCmd::Exception.new('mite configure needs two arguments, the account name and the apikey') if arguments.size < 2

      settings = {:account => arguments[0], :apikey => arguments[1]}
      settings[:autocomplete_notes] = MiteCmd.autocomplete_notes
      settings[:autocomplete_always_quote] = MiteCmd.autocomplete_always_quote
      settings[:colorize] = MiteCmd.colorize
      write_configuration(settings)

      tell("warning: ouldn't set up bash completion".colorize(:yellow)) unless try_to_setup_bash_completion
    end

    def self.method_list
      {
        'auto-complete' => {
          :method => :auto_complete,
          :description => "not for direct use, only called from bash for tab-completion",
        },
        'configure' => {
          :method => :configure,
          :arguments => %w{apikey user},
          :description => "create .mite.yml file with required basic settings",
        },
        'help' => {
          :method => :help,
          :description => "show help and exit",
        },
        'lunch' => {
          :method => :stop,
          :description => "halt active time tracker (same as stop)",
        },
        'note' => {
          :method => :note,
          :arguments => %w{message ...},
          :description => "create initial time entry",
        },
        'open' => {
          :method => :open,
          :description => "visit your mite interface with your browser",
        },
        'pause' => {
          :method => :stop,
          :description => "halt active time tracker (same as stop)",
        },
        'rebuild-cache' => {
          :method => :rebuild_cache,
          :description => "sync local cache of projects/services for tab-completion",
        },
        'start' => {
          :method => :start,
          :description => "start active time tracker",
        },
        'stop' => {
          :method => :stop,
          :description => "halt active time tracker",
        },
        'add' => {
          :method => :create_time_entry,
          :arguments => %w{time project service [notes [...]]},
          :description => "create new time entry",
        },
        'preview' => {
          :method => :prepare_time_entry,
          :arguments => %{time project service [notes [...]]},
          :description => "same as 'add', but don't persist entry to server yet",
        },
        'delete' => {
          :method => :destroy_time_entry,
          :arguments => %w{index},
          :description => "delete time entry with specified numeric index",
        },
        'reword' => {
          :method => :reword_time_entry,
          :arguments => %w{index notes ...},
          :description => "change message in entry with numeric index",
        },
        'report' => {
          :method => :report,
          :arguments => %w{[time-frame]},
          :description => "show report for 'today', 'yesterday', 'last_week', 'last_month' or 'YYYY-MM-DD'",
        },
      }
    end

    def self.command_list
      method_list.keys
    end

    def method_for_command(command)
      self.class.method_list[command][:method]
    end

    def command_description_list
      self.class.method_list.map do |command,info|
        info[:arguments] ||= []
        "  %s %s\n    %s" % [ command, [ info[:arguments] ].flatten * " ", info[:description] ]
      end
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
      tell option_parser.help
      tell "\navailable commands:"
      tell command_description_list * "\n"
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
      @parser ||= OptionParser.new do |opts|
        opts.banner = "Usage: mite [options] <command> [arguments]\n\noptions:"
        opts.on("-d", "--date DATE",
                "Create or report on specific day, e.g. today, yesterday, YYYY-MM-DD, ...") { |arg| @date = arg }
        opts.on("-x", "--really",
                "Confirm destructive actions such as delete") { |arg| @confirmed = arg }
        opts.on("-n", "--noop",
                "Noop mode. Only useful with 'mite add', basically turning it into 'mite preview'.") { |arg| @noop = true }
        opts.on("-c", "--[no-]color",
                "Use terminal colors. (See :colorize in .mite.yml)") { |arg| MiteCmd.colorize = arg }
        opts.on("-N", "--[no-]autocomplete-notes",
                "Whether notes should be downloaded to the tab-completion cache. Only useful with 'mite configure'.") { |arg| MiteCmd.autocomplete_notes = arg }
        opts.on("-Q", "--[no-]autocomplete-always-quote",
                "Whether projects and services should always be quoted for tab-completion. Only useful with 'mite configure'.") { |arg| MiteCmd.autocomplete_always_quote = arg }
      end
    end

    def ask_for_confirmation(message)
      if @confirmed
        yield
        true
      else
        tell "#{message} - add --really to confirm".colorize(:yellow)
        false
      end
    end

  end
end
