require 'rubygems'
require 'rake'
require 'bundler/gem_helper'

task default: :test

require './test/setup'

desc 'Run all tests'
task :test do
  ::Dir['./test/test__*.rb'].each { |f| require f }
  session = Specular.new
  session.boot { include Sonar }
  session.before do |app|
    if app && app.respond_to?(:base_url)
      app(app)
      map(app.base_url)
      get
    end
  end
  session.run /SonarTest/, trace: true
  puts session.failures if session.failed?
  puts session.summary
  session.exit_code
end

Bundler::GemHelper.install_tasks
