require 'active_support'
I18n.enforce_available_locales = false
I18n.load_path << File.join(File.dirname(__FILE__), 'config', 'locales', 'en.yml')

module MongoidOrderable
  SUPPORTED_MONGOID_VERSIONS = [2, 3, 4, 5]

  SUPPORTED_MONGOID_VERSIONS.each do |version|
    self.class.instance_eval do
      define_method "mongoid#{version}?" do
        ::Gem::Version.new(::Mongoid::VERSION).segments.first == version
      end
    end
  end

  def self.inc instance, attribute, value
    if MongoidOrderable.mongoid2? || MongoidOrderable.mongoid3?
      instance.inc attribute, value
    else
      instance.inc(attribute => value)
    end
  end

  def self.metadata instance
    if MongoidOrderable.mongoid2? || MongoidOrderable.mongoid3?
      instance.metadata
    else
      instance.relation_metadata
    end
  end
end

require 'mongoid'
require 'mongoid_orderable/version'

if MongoidOrderable.mongoid2?
  require 'mongoid_orderable/mongoid/contexts/mongo'
  require 'mongoid_orderable/mongoid/contexts/enumerable'
  require 'mongoid_orderable/mongoid/criteria'
else
  require 'mongoid_orderable/mongoid/contextual/memory'
end

require 'mongoid/orderable'
require 'mongoid/orderable/errors'
require 'mongoid/orderable/configuration'
require 'mongoid/orderable/helpers'
require 'mongoid/orderable/callbacks'
require 'mongoid/orderable/listable'
require 'mongoid/orderable/movable'

require 'mongoid/orderable/generator/listable'
require 'mongoid/orderable/generator/movable'
require 'mongoid/orderable/generator/position'
require 'mongoid/orderable/generator/scope'
require 'mongoid/orderable/generator/helpers'
require 'mongoid/orderable/generator'

require 'mongoid/orderable/orderable_class'
