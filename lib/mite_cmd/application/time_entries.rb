require 'date'

module MiteCmd
  module Application::TimeEntries

    def create_time_entry(arguments)
      time_entry = prepare_time_entry(arguments)
      time_entry.save unless @noop
    end

    def prepare_time_entry(arguments)
      attributes = @default_attributes
      if @date
        attributes.merge!(self.parse_date_parameter!)
      end

      begin
        attributes.merge! fill_in_time_entry_attributes!(arguments)
      rescue MiteCmd::Exception => e
        help arguments
        raise e
      end

      if attributes[:_start_tracker]
        start_tracker = true
        attributes.delete :_start_tracker
      end

      time_entry = Mite::TimeEntry.new attributes
      time_entry.start_tracker if start_tracker
      tell time_entry.inspect
      time_entry
    end

    def fill_in_time_entry_attributes!(arguments)
      attributes = {}

      if arguments[0] =~ MiteCmd::Application::TIME_FORMAT
        time_string = arguments[0]
        attributes[:minutes] = parse_minutes(time_string)
        if time_string =~ /\+$/
          attributes[:_start_tracker] = true
        end
      else
        raise MiteCmd::Exception.new "the first argument to 'mite add' must be a time specification"
      end

      if project = find_or_create_project(arguments[1])
        attributes[:project_id] = project.id
      end
      if @arguments[2] && service = find_or_create_service(arguments[2])
        attributes[:service_id] = service.id
      end
      if note = arguments[3..-1] * " "
        attributes[:note] = note
      end

      if !project.id || !service.id || !note
        raise "missing project/service/note"
      end

      attributes
    end

    # Dates like 'last_week', 'yesterday' etc. are not applicable when posting new entries
    def parse_date_parameter!
      case @date
      when 'today'
        {}
      when 'yesterday'
        { :date_at => ( DateTime.now - 1 ).strftime("%Y-%m-%d") }
      when /^\d{4}-\d{2}-\d{2}/
        { :date_at => @date }
      when 'last_week', 'last_month'
        raise MiteCmd::Exception.new "the special time format '#{@date}' is not applicable when adding new time entries"
      else
        raise MiteCmd::Exception.new "unrecognized date format '#{@date}'"
      end
    end

    def current
      tell Mite::Tracker.current ? Mite::Tracker.current.inspect : "No current entry"
    end

    def report(arguments)
      if arguments.length > 1
        raise MiteCmd::Exception.new "The report subcommand takes exactly one argument with a time specification"
      elsif arguments.length == 1
        report_date = arguments[0]
      end

      if @date
        if report_date
          tell "warning: ignoring report argument '#{arguments[0]}' in favor of date parameter '#{@date}'".colorize(:yellow)
        end
        report_date = @date
      end

      report_date ||= "today"

      count = 0
      total_minutes = 0
      total_revenue = Mite::TimeEntry.all(:params => {:at => report_date, :user_id => 'current'}).each do |time_entry|
        total_minutes += time_entry.minutes
        tell "%3d %s" % [ count, time_entry.inspect ]
        count += 1
      end.map(&:revenue).compact.sum
      tell ("     %s:%.2d" % [total_minutes/60, total_minutes-total_minutes/60*60]).colorize(:lightred) + ", " + ("%.2f $" % (total_revenue/100)).colorize(:lightgreen)
    end

    def get_indexed_entry(index)
      date = @date || 'today'

      entries = Mite::TimeEntry.all(:params => {:at => date, :user_id => 'current'})
      unless entry = entries[index]
        raise MiteCmd::Exception.new "Found no entry with index #{reword_index} to reword"
      end
      entry
    end

    def destroy_time_entry(arguments)
      entry = get_indexed_entry(arguments.shift.to_i)

      tell entry.inspect

      ask_for_confirmation "not destroying the specified entry" do
        entry.destroy
        tell "the above entry has been permanently removed".colorize(:red)
      end
    end

    def reword_time_entry(arguments)
      entry = get_indexed_entry(arguments.shift.to_i)

      tell "Rewording the following entry".colorize(:green)
      tell entry.inspect
      entry.note = arguments * " "
      tell "into the following".colorize(:green)
      tell entry.inspect

      ask_for_confirmation "not actually rewording the specified entry yet" do
        entry.save
      end
    end

    def start(arguments)
      if time_entry = Mite::TimeEntry.first(:params => {:at => 'today'})
        time_entry.start_tracker
        tell time_entry.inspect
      else
        tell "could'nt find any time entry for today"
      end
    end

    def stop(arguments)
      if current_tracker = (Mite::Tracker.current ? Mite::Tracker.current.stop : nil)
        tell current_tracker.time_entry.inspect
      end
    end

    def find_or_create_by_name(repository, name)
      object = repository.first(:params => {:name => name})
      return nil if name =~ MiteCmd::Application::TIME_FORMAT
      object ? object : repository.create(:name => name)
    end

    def find_or_create_project(name)
      find_or_create_by_name(Mite::Project, name)
    end

    def find_or_create_service(name)
      find_or_create_by_name(Mite::Service, name)
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

    def note(arguments)
      if time_entry = Mite::TimeEntry.first(:params => {:at => 'today'})
        time_entry.note = [time_entry.note, *arguments].compact.join(' ')
        time_entry.save
        tell time_entry.inspect
      end
    end

  end
end
