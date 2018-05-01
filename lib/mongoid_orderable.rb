require 'active_support'

I18n.enforce_available_locales = false if I18n.respond_to?(:enforce_available_locales)
I18n.load_path << File.join(File.dirname(__FILE__), 'config', 'locales', 'en.yml')

require 'mongoid'
require 'mongoid/compatibility'

module MongoidOrderable
  if ::Mongoid::Compatibility::Version.mongoid3?
    def self.inc(instance, attribute, value)
      instance.inc attribute, value
    end

    def self.metadata(instance)
      instance.metadata
    end
  elsif ::Mongoid::Compatibility::Version.mongoid7?
    def self.inc(instance, attribute, value)
      instance.inc(attribute => value)
    end

    def self.metadata(instance)
      instance._association
    end
  else
    def self.inc(instance, attribute, value)
      instance.inc(attribute => value)
    end

    def self.metadata(instance)
      instance.relation_metadata
    end
  end
end

require 'mongoid_orderable/version'

require 'mongoid_orderable/mongoid/contextual/memory'

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
