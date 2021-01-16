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

  gem.files         = Dir.glob('lib/**/*') + %w[CHANGELOG.md LICENSE.txt README.md Rakefile]
  gem.test_files    = Dir.glob('spec/**/*')
  gem.require_path  = 'lib'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec', '>= 3.0.0'
  gem.add_development_dependency 'rubocop', '>= 1.8.1'
  gem.add_runtime_dependency 'mongoid', '>= 7.0.0'
end
