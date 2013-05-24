require 'rubygems'
require 'rake'
require "bundler/gem_tasks"

task :spec do
  spec_files = Dir.glob('spec/**/*_spec.rb').join(' ')
  sh "spec #{spec_files} --format specdoc --color"
end
task :default => :spec

task :rcov do
  sh "rake run_rcov && open coverage/index.html"
end
require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:run_rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end
