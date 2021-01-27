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
  config.order = 'random'

  config.before(:each) do
    Mongoid.purge!
    Mongoid.models.each do |model|
      model.create_indexes if model.name =~ /Mongoid::Orderable::Models/
    end
  end
end

require_relative 'support/models'

def set_transactions(enabled)
  Mongoid.models.each do |model|
    next unless model.respond_to?(:orderable_configs)
    model.orderable_configs.values.each do |config|
      config[:use_transactions] = enabled
    end
  end
end

def enable_transactions!
  before { set_transactions(true) }
end

def disable_transactions!
  before { set_transactions(false) }
end
