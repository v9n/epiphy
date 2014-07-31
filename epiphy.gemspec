lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'epiphy/version'

Gem::Specification.new do |s|
  s.name        = 'epiphy'
  s.version     = Epiphy::VERSION
  s.date        = '2010-04-28'
  s.summary     = "RethinkDB ORM"
  s.description = "A simple ORM for RethinkDB. Stealing Lotus::Model to learn how to write an ORM and API design"
  s.authors     = ["Vinh"]
  s.email       = 'kurei@axcoto.com'
  s.homepage    = 'http://rubygems.org/gems/epiphy'
  s.license     = 'MIT'

  s.files         = `git ls-files -z -- lib/* CHANGELOG.md EXAMPLE.md LICENSE.md README.md lotus-model.gemspec`.split("\x0")
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 2.0.0'

  #s.add_runtime_dependency 'lotus-utils', '~> 0.2'

  s.add_development_dependency 'bundler',  '~> 1.6'
  s.add_development_dependency 'minitest', '~> 5'
  s.add_development_dependency 'rake',     '~> 10'
end
