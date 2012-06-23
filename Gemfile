source "http://rubygems.org"

# Specify your gem's dependencies in mongoid_orderable.gemspec
gemspec

case version = ENV['MONGOID_VERSION'] || "~> 3.0.0.rc"
when /2/
  gem "mongoid", "~> 2.4.0"
else
  gem "mongoid", version
end
