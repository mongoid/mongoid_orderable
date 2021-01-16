# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

case version = ENV['MONGOID_VERSION'] || '7'
when 'HEAD'
  gem 'mongoid', github: 'mongodb/mongoid'
when /\A7/
  gem 'mongoid', '~> 7.0'
else
  gem 'mongoid', version
end

group :test do
  gem 'rubocop', '0.45.0'
end
