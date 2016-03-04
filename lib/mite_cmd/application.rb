require 'mite_cmd/autocomplete/cached.rb'

if RUBY_VERSION >= '1.9'
  require 'fileutils'
else
  require 'ftools'
end

module MiteCmd
  class Application
    TIME_FORMAT = /^(\d+(\.\d+)?:?\+?)$|(\d+:\d+\+?)$|\+$/

    def initialize(arguments=[])
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

    def auto_complete(arguments)
      autocomplete = MiteCmd::Autocomplete::Cached.new(MiteCmd.calling_script)
      #autocomplete.completion_table = MiteCmd::CompletionTable.new(cache_file)
      if MiteCmd.autocomplete_always_quote
        autocomplete.suggestions.map(&:quote).each { |s| tell s }
      else
        autocomplete.suggestions.map(&:quote_if_spaced).each { |s| tell s }
      end
    end

    def configure(arguments)
      raise MiteCmd::Exception.new('mite configure needs two arguments, the account name and the apikey') if @arguments.size < 3
      MiteCmd.load_configuration

      settings = {:account => @arguments[1], :apikey => @arguments[2]}
      settings[:autocomplete_notes] = MiteCmd.autocomplete_notes
      settings[:autocomplete_always_quote] = MiteCmd.autocomplete_always_quote
      write_configuration(settings)

      tell("Couldn't set up bash completion. I'm terribly frustrated. Maybe 'mite help' helps out.") unless try_to_setup_bash_completion
    end

    def create_time_entry(arguments)
      time_entry = prepare_time_entry(arguments)
      time_entry.save
    end

    def prepare_time_entry(arguments)
      attributes = @default_attributes
      if time_string = arguments.select { |a| a =~ TIME_FORMAT }.first
        attributes[:minutes] = parse_minutes(time_string)
        start_tracker = (time_string =~ /\+$/)
      end
      if project = find_or_create_project(arguments.first)
        attributes[:project_id] = project.id
      end
      if @arguments[1] && service = find_or_create_service(arguments[1])
        attributes[:service_id] = service.id
      end
      if note = parse_note(arguments, time_string)
        attributes[:note] = note
      end
      time_entry = Mite::TimeEntry.new attributes
      time_entry.start_tracker if start_tracker
      tell time_entry.inspect
      time_entry
    end

    def current
      tell Mite::Tracker.current ? Mite::Tracker.current.inspect : "No current entry"
    end

    def method_for_command(command)
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
      }[command]
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

    def note(arguments)
      if time_entry = Mite::TimeEntry.first(:params => {:at => 'today'})
        time_entry.note = [time_entry.note, *arguments].compact.join(' ')
        time_entry.save
        tell time_entry.inspect
      end
    end

    def open(arguments)
      open_or_echo Mite.account_url
    end

    def rebuild_cache(arguments)
      rebuild_completion_table
      tell 'The rebuilding of the cache has been done, Master. Your wish is my command.'
    end

    def report(arguments)
      total_minutes = 0
      total_revenue = Mite::TimeEntry.all(:params => {:at => arguments, :user_id => 'current'}).each do |time_entry|
        total_minutes += time_entry.minutes
        tell time_entry.inspect
      end.map(&:revenue).compact.sum
      tell ("%s:%.2d" % [total_minutes/60, total_minutes-total_minutes/60*60]).colorize(:lightred) + ", " + ("%.2f $" % (total_revenue/100)).colorize(:lightgreen)
    end

    def start(arguments)
      if time_entry = Mite::TimeEntry.first(:params => {:at => 'today'})
        time_entry.start_tracker
        tell time_entry.inspect
      else
        tell "Oh my dear! I tried hard, but I could'nt find any time entry for today."
      end
    end

    def stop(arguments)
      if current_tracker = (Mite::Tracker.current ? Mite::Tracker.current.stop : nil)
        tell current_tracker.time_entry.inspect
      end
    end

    def find_or_create_by_name(repository, name)
      object = repository.first(:params => {:name => name})
      return nil if name =~ TIME_FORMAT
      object ? object : repository.create(:name => name)
    end

    def find_or_create_project(name)
      find_or_create_by_name(Mite::Project, name)
    end

    def find_or_create_service(name)
      find_or_create_by_name(Mite::Service, name)
    end

    def parse_note(args, time_string)
      if args[3]
        args[3]
      elsif time_string.nil? && args[2]
        args[2]
      elsif time_string && args[args.index(time_string)+1]
        args[args.index(time_string)+1]
      else
        nil
      end
    end

    def parse_minutes(string)
      string = string.sub(/\+$/, '')

      if string.blank?
        0
      elsif string =~ /^\d+:\d+$/
        string.split(':').first.to_i*60 + string.split(':').last.to_i
      elsif string =~ /^\d+(\.\d+)?:?$/
        (string.to_f*60).to_i
      end
    end

    def rebuild_completion_table
      MiteCmd::CompletionTable.new(cache_file).rebuild
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
