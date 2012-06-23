module MongoidOrderable
  def self.mongoid2?
    Mongoid.const_defined? :Contexts
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
