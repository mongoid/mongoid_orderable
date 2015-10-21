require 'bundler'
Bundler.require

if ::Mongoid::Compatibility::Version.mongoid2?
  Mongoid.configure do |config|
    config.master = Mongo::Connection.new.db 'mongoid_orderable_test'
    config.logger = nil
  end
else
  Mongoid.configure do |config|
    config.connect_to 'mongoid_orderable_test'
  end
end

unless Mongoid::Compatibility::Version.mongoid2?
  Mongoid.logger.level = Logger::INFO
  Mongo::Logger.logger.level = Logger::INFO if Mongoid::Compatibility::Version.mongoid5?
end

RSpec.configure do |config|
  config.after(:all) do
    if Mongoid::Compatibility::Version.mongoid2?
      Mongoid.master.connection.drop_database(Mongoid.database.name)
    elsif Mongoid::Compatibility::Version.mongoid3? || Mongoid::Compatibility::Version.mongoid4?
      Mongoid.default_session.drop
    else
      Mongoid::Clients.default.database.drop
    end
  end
end
