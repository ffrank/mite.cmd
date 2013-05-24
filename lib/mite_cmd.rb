require 'yaml'
Dir[File.join(File.dirname(__FILE__), *%w[.. vendor * lib])].each do |path|
  $LOAD_PATH.unshift path
end
require 'mite-rb'

require 'string_ext'
require 'mite_ext'
require 'mite_cmd/application'
require 'mite_cmd/autocomplete'

module MiteCmd
  BASH_COMPLETION = "complete -C \"mite auto-complete\" mite"

  CONFIG_FILE = File.expand_path '~/.mite.yml'

  mattr_accessor :calling_script

  def self.load_configuration
    if File.exist?(configuration_file_path)
      configuration = YAML.load(File.read(configuration_file_path))
      Mite.account = configuration[:account]
      Mite.key = configuration[:apikey]
    else
      raise Exception.new("Configuration file is missing.")
    end
  end

  def self.configuration_file_path
    CONFIG_FILE
  end

  def self.run(args)
    Application.new(args).run
  end

  class Exception < StandardError; end
end
