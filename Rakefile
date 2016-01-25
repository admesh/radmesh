require 'rake/testtask'
require 'rubocop/rake_task'

RuboCop::RakeTask.new

Rake::TestTask.new do |t|
  t.pattern = 'spec/*_spec.rb'
end

task default: [:rubocop, :test]
