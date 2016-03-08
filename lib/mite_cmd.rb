require 'yaml'
Dir[File.join(File.dirname(__FILE__), *%w[.. vendor * lib])].each do |path|
  $LOAD_PATH.unshift path
end
require 'mite-rb'

require 'string_ext'
require 'mite_ext'
require 'mite_cmd/application'
require 'mite_cmd/application/main'
require 'mite_cmd/autocomplete'
require 'mite_cmd/completion_table'

module MiteCmd
  BASH_COMPLETION = "complete -C \"mite auto-complete\" mite"

  CONFIG_FILE = File.expand_path '~/.mite.yml'

  mattr_accessor :calling_script, :autocomplete_notes, :autocomplete_always_quote

  def self.load_configuration
    # defaults
    self.autocomplete_notes = true
    self.autocomplete_always_quote = false

    begin
      load_configuration!
    rescue MiteCmd::Exception
      # nothing - this variant does not raise
    end
  end

  def self.load_configuration!
    if ! File.exist?(configuration_file_path)
      raise MiteCmd::Exception.new("Configuration file is missing.")
    end

    configuration = YAML.load(File.read(configuration_file_path))
    Mite.account = configuration[:account]
    Mite.key = configuration[:apikey]

    if configuration.has_key? :autocomplete_notes
      self.autocomplete_notes = configuration[:autocomplete_notes]
    end

    if configuration.has_key? :autocomplete_always_quote
      self.autocomplete_always_quote = configuration[:autocomplete_always_quote]
    end
  end

  def self.configuration_file_path
    CONFIG_FILE
  end

  def self.run(args)
    Application::Main.new(args).run
  end

  class Exception < StandardError; end
end
