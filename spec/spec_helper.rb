$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'mite_cmd'

RSpec.configure do |config|
  config.before(:each) do
    use_spec_configuration
  end
end

# Use this method in a before block to ensure we don't use the users actual
# mite.rb configuration file at ~/.mite.rb when calling MiteCmd.load_configuration
def use_spec_configuration
  MiteCmd.stub(:configuration_file_path).and_return(
    File.join(File.dirname(__FILE__), 'fixtures', 'mite.yml')
  )
end
