require 'rake/clean'
require 'rake/testtask'

APP_FILE = 'app.rb'
APP_CLASS = 'WSApp::App'

task default: :test

Rake::TestTask.new(:test) do |t|
  t.test_files = FileList['test/**/*_test.rb']
  t.warning = false
end

require_relative 'app'
