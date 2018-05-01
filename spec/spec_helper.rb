require 'bundler'
Bundler.require

Mongoid.configure do |config|
  config.connect_to 'mongoid_orderable_test'
end

Mongoid.logger.level = Logger::INFO
Mongo::Logger.logger.level = Logger::INFO if Mongoid::Compatibility::Version.mongoid5_or_newer?

Mongoid::Config.belongs_to_required_by_default = false if Mongoid::Compatibility::Version.mongoid6?

RSpec.configure do |config|
  config.after(:all) do
    if Mongoid::Compatibility::Version.mongoid3? || Mongoid::Compatibility::Version.mongoid4?
      Mongoid.default_session.drop
    else
      Mongoid::Clients.default.database.drop
    end
  end
end
