# encoding: utf-8
require 'bundler'
require 'rake'
require 'rake/testtask'

#begin
  #Bundler.setup(:default, :development)
#rescue Bundler::BundlerError => e
  #$stderr.puts e.message
  #$stderr.puts "Run `bundle install` to install missing gems"
  #exit e.status_code
#end

Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "epiphy #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
