require 'bundler'
Bundler.require

DATABASE_NAME = "mongoid_#{Process.pid}"

if MongoidOrderable.mongoid2?
  Mongoid.configure do |config|
    # database = Mongo::Connection.new.db DATABASE_NAME
    # database.add_user "mongoid", "test"
    config.master = Mongo::Connection.new.db DATABASE_NAME
    config.logger = nil
  end
else
  Mongoid.configure do |config|
    config.connect_to DATABASE_NAME
  end
end

RSpec.configure do |config|
  config.mock_with :rspec

  config.before :suite do
    #DatabaseCleaner[:mongoid].strategy = :truncation
  end

  config.after :each do
    #DatabaseCleaner[:mongoid].clean
  end

  config.after(:suite) do
    if MongoidOrderable.mongoid2?
      Mongoid.master.connection.drop_database DATABASE_NAME
    else
      Mongoid.default_session.drop
    end
  end
end
