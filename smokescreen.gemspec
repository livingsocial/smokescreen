# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'smokescreen/version'

Gem::Specification.new do |spec|
  spec.name          = "smokescreen"
  spec.version       = Smokescreen::VERSION
  spec.authors       = ["Dan Mayer"]
  spec.email         = ["dan.mayer@livingsocial.com"]
  spec.description   = %q{Smokescreen is a smoke test suite that tries to run the most critical and most likely effected tests related to recent changes.}
  spec.summary       = %q{Smokescreen the minimal final smoke tests for a project}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_dependency "rake"
end
