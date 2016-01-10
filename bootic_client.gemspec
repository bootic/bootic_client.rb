# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bootic_client/version'

Gem::Specification.new do |spec|
  spec.name          = "bootic_client"
  spec.version       = BooticClient::VERSION
  spec.authors       = ["Ismael Celis"]
  spec.email         = ["ismaelct@gmail.com"]
  spec.description   = %q{Official Ruby client for the Bootic API}
  spec.summary       = %q{Official Ruby client for the Bootic API}
  spec.homepage      = "https://developers.bootic.net"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", '~> 0.9'
  spec.add_dependency "uri_template", '~> 0.7'
  spec.add_dependency "faraday_middleware", '~> 0.9'
  spec.add_dependency "faraday-http-cache", '1.2.2'
  spec.add_dependency "net-http-persistent", '~> 2.9'
  spec.add_dependency "oauth2", "~> 1"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "jwt"
  spec.add_development_dependency "dalli"
end
