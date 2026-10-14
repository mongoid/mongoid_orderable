# frozen_string_literal: true

source 'https://rubygems.org'

gem 'rake'
gem 'rspec', '>= 3.0.0'
gem 'rspec-retry'
gem 'rubocop', '~> 1.50.0'
gemspec

gem 'bigdecimal' if RUBY_VERSION >= '3.4'
gem 'logger' if RUBY_VERSION >= '3.4'

case version = ENV['MONGOID_VERSION'] || '9'
when 'HEAD'
  gem 'mongoid', github: 'mongodb/mongoid'
when /\A\d+\z/
  gem 'mongoid', "~> #{version}.0"
else
  gem 'mongoid', version
end
