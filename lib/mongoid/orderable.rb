module Mongoid::Orderable
  extend ActiveSupport::Concern

  included do
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
    end

  end
end
