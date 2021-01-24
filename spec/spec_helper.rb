require 'bundler'
Bundler.require
require 'rspec'
require 'rspec/retry'

Mongoid.configure do |config|
  config.connect_to 'mongoid_orderable_test'
end

Mongoid.logger.level = Logger::INFO
Mongo::Logger.logger.level = Logger::INFO
Mongoid::Config.belongs_to_required_by_default = false

RSpec.configure do |config|
  config.before(:each) do
    Mongoid.purge!
    Mongoid.models.each do |model|
      model.create_indexes if model.name =~ /Mongoid::Orderable::Models/
    end
  end
end
