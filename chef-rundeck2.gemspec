# encoding: utf-8
# rubocop: disable LineLength

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'chef-rundeck/version'

Gem::Specification.new do |spec|
  spec.name          = 'chef-rundeck2'
  spec.version       = ChefRunDeck::VERSION
  spec.authors       = ['Brian Dwyer']
  spec.email         = ['bdwyer@IEEE.org']

  spec.summary       = %q(Chef Options Provider for RunDeck with Extras)
  # => spec.description   = %q(TODO: Write a longer description or delete this line.)
  spec.homepage      = 'https://github.com/bdwyertech/chef-rundeck2'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # => Dependencies
  spec.add_runtime_dependency 'chef-api', '~> 0.6'
  spec.add_runtime_dependency 'mixlib-cli', '~> 1.7'
  spec.add_runtime_dependency 'rack-cache', '~> 1.6'
  spec.add_runtime_dependency 'sinatra', '~> 1.4'
  spec.add_runtime_dependency 'sinatra-contrib', '~> 1.4'

  # => Development Dependencies
  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop'
end
