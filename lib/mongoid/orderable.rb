module Mongoid::Orderable
  extend ActiveSupport::Concern

  included do
    extend  Mongoid::Orderable::Configurable
    include Mongoid::Orderable::Helpers
    include Mongoid::Orderable::Callbacks
    include Mongoid::Orderable::Movable
    include Mongoid::Orderable::Listable
  end

  module ClassMethods
    attr_accessor :orderable_configurations

    def orderable options = {}
      configuration = Mongoid::Orderable::Configuration.build(self, options)

      Mongoid::Orderable::OrderableClass.setup(self, configuration)

      define_orderable_scope

      generate_orderable_class_helpers

      add_orderable_callbacks
    end

    def orderable_config(column = nil)
      column ? orderable_configurations[column] : orderable_configurations.first.last
    end


  end
end
