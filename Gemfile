# frozen_string_literal: true

source 'https://rubygems.org'

gem 'rake'
gem 'rspec', '>= 3.0.0'
gem 'rspec-retry'
gem 'rubocop', '>= 1.8.1'
gemspec

case version = ENV['MONGOID_VERSION'] || '7'
when 'HEAD'
  gem 'mongoid', github: 'mongodb/mongoid'
when /\A7/
  gem 'mongoid', '~> 7.0'
else
  gem 'mongoid', version
end
