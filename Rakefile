require 'rake/testtask'
require 'rubocop/rake_task'
require 'yard'

RuboCop::RakeTask.new

Rake::TestTask.new do |t|
  t.pattern = 'spec/*_spec.rb'
end

YARD::Rake::YardocTask.new do |t|
  t.options << '--title'
  t.options << 'ADMesh'
end

task default: [:rubocop, :test]
task doc: [:yard]
