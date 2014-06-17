module Mongoid::Orderable
  extend ActiveSupport::Concern

  included do
    extend  Mongoid::Orderable::Configurable
    include Mongoid::Orderable::Helpers
    include Mongoid::Orderable::Callbacks
    include Mongoid::Orderable::Movable
    include Mongoid::Orderable::Listable

    def orderable_keys
      orderable_inherited_class.orderable_configurations.keys
    end
  end

  module ClassMethods
    attr_accessor :orderable_configurations

    def orderable options = {}
      configuration = Mongoid::Orderable::Configuration.build(self, options)

      Mongoid::Orderable::OrderableClass.setup(self, configuration)

      define_orderable_scope(configuration[:column], configuration[:scope])

      define_position_helpers(configuration[:column])

      generate_orderable_class_helpers

      add_orderable_callbacks
    end

  end
end
