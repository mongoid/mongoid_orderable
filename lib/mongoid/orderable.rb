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
    def orderable options = {}
      setup_orderable_class(options)

      add_mongoid_field_and_index

      add_orderable_callbacks
    end

    private

    def add_mongoid_field_and_index
      field configuration[:column], orderable_field_opts

      if configuration[:index]
        if MongoidOrderable.mongoid2?
          index configuration[:column]
        else
          index(configuration[:column] => 1)
        end
      end
    end

    def orderable_field_opts
      field_opts = { :type => Integer }
      field_opts.merge!(configuration.slice(:as))
      field_opts
    end

  end
end
