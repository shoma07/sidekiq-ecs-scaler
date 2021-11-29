# frozen_string_literal: true

require "bundler/gem_tasks"

# rspec
require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)

# rubocop
require "rubocop/rake_task"
RuboCop::RakeTask.new(:lint) do |t|
  t.options = %w[--parallel]
end
namespace :lint do
  desc "Lint fix (Rubocop)"
  task fix: :auto_correct
end

# steep
# @see https://github.com/soutaro/steep/blob/master/exe/steep
require "steep"
require "steep/cli"
desc "Typecheck (Steep)"
task :typecheck do
  Steep::CLI.new(
    argv: %w[check -j4], stdout: $stdout, stderr: $stderr, stdin: $stdin
  ).run.zero? || exit(1)
end

# yard
## custom rake task
require "yard"
desc "document"
task :doc do
  YARD::CLI::CommandParser.run
  `yard`.lines(chomp: true).last.match(/\d+/)[0].to_i == 100 || exit(1)
end

task default: %i[lint typecheck spec doc]
