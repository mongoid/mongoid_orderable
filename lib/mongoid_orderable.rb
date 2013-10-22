module MongoidOrderable
  def self.mongoid2?
    ::Mongoid.const_defined? :Contexts
  end
  def self.mongoid3?
    ::Mongoid.const_defined? :Observer
  end
  def self.inc instance, attribute, value
    if MongoidOrderable.mongoid2? || MongoidOrderable.mongoid3?
      instance.inc attribute, value
    else
      instance.inc(attribute => value)
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
