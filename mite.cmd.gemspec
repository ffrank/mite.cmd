Gem::Specification.new do |s|
  s.name = %q{mite.cmd}
  s.version = "0.1.12"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Lukas Rieder"]
  s.date = %q{2012-05-09}
  s.default_executable = %q{mite}
  s.description = %q{A simple command line interface for mite, a sleek time tracking webapp.}
  s.email = %q{l.rieder@gmail.com}
  s.executables = ["mite"]
  s.extra_rdoc_files = [
    "LICENSE",
    "README.textile",
    "TODO"
  ]
  s.files = [
    "Gemfile",
    "LICENSE",
    "README.textile",
    "Rakefile",
    "TODO",
    "VERSION",
    "bin/mite",
    "lib/mite_cmd.rb",
    "lib/mite_cmd/application.rb",
    "lib/mite_cmd/autocomplete.rb",
    "lib/mite_ext.rb",
    "lib/string_ext.rb",
    "mite.cmd.gemspec",
    "spec/mite_cmd/application_spec.rb",
    "spec/mite_cmd/autocomplete_spec.rb",
    "spec/mite_cmd_spec.rb",
    "spec/mite_ext_spec.rb",
    "spec/spec_helper.rb",
    "spec/string_ext_spec.rb"
  ]
  s.homepage = %q{http://github.com/Overbryd/mite.cmd}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{A simple command line interface for basic mite tasks.}

  s.add_runtime_dependency 'activeresource', '~> 3.1'
  s.add_runtime_dependency 'activesupport', '~> 3.1'
  s.add_runtime_dependency 'json', '~> 1.7.7'
  s.add_runtime_dependency 'mite-rb', '~> 0.5'

  s.add_development_dependency 'rake', '>= 0'
  s.add_development_dependency 'rspec', '~> 1.3.2'
end

