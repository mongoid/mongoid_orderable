module Mongoid::Orderable
  extend ActiveSupport::Concern

  included do
    include Mongoid::Orderable::Helpers
    include Mongoid::Orderable::Callbacks
    include Mongoid::Orderable::Movable
    include Mongoid::Orderable::Listable

    class_attribute :orderable_configurations
  end

  module ClassMethods
    def orderable(options = {})
      configuration = Mongoid::Orderable::Configuration.build(self, options)

      Mongoid::Orderable::OrderableClass.setup(self, configuration)
    end
  end
end
