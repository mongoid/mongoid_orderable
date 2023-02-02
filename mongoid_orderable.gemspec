# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'mongoid/orderable/version'

Gem::Specification.new do |gem|
  gem.name        = 'mongoid_orderable'
  gem.version     = Mongoid::Orderable::VERSION
  gem.authors     = ['pyromaniac']
  gem.email       = ['kinwizard@gmail.com']
  gem.homepage    = 'https://github.com/mongoid/mongoid_orderable'
  gem.summary     = 'Mongoid orderable list implementation'
  gem.description = 'Enables Mongoid models to track their position in list'
  gem.license     = 'MIT'

  gem.files         = Dir.glob('lib/**/*') + %w[CHANGELOG.md LICENSE.txt README.md Rakefile]
  gem.require_path  = 'lib'

  gem.add_runtime_dependency 'mongoid', '>= 7.0.0'
  gem.metadata['rubygems_mfa_required'] = 'true'
end
