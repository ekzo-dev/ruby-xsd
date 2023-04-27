# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

desc 'Run all specs'
RSpec::Core::RakeTask.new(:spec)  do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.verbose = false
end

require 'rubocop/rake_task'

RuboCop::RakeTask.new do |t|
  t.options = ['--display-cop-names']
end

desc 'Run tests'
task test: :spec

desc 'Run linter'
task lint: :rubocop

desc 'Run linter and tests'
task default: %i[lint spec]
