require 'bundler'
Bundler.require

DATABASE_ID = Process.pid

Mongoid.configure do |config|
  database = Mongo::Connection.new.db("mongoid_#{DATABASE_ID}")
  database.add_user("mongoid", "test")
  config.master = database
  config.logger = nil
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
    Mongoid.master.connection.drop_database("mongoid_#{DATABASE_ID}")
  end
end
