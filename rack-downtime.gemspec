# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rack/downtime/version'

Gem::Specification.new do |spec|
  spec.name          = "rack-downtime"
  spec.version       = Rack::Downtime::VERSION
  spec.authors       = ["Skye Shaw"]
  spec.email         = ["skye.shaw@gmail.com"]
  spec.summary       = %q{Planned downtime management for Rack applications}
  spec.description   =<<DOC
Rack::Downtime provides a variety of ways to easily trigger and display planned maintenance notifications to users
while a site is still up. Various strategies are provided that will work with sites of all sizes.
DOC

  spec.homepage      = "https://github.com/sshaw/rack-downtime"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri"
  spec.add_dependency "rack", "~> 1"
  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
