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
      field orderable_config[:column], orderable_field_opts

      if orderable_config[:index]
        if MongoidOrderable.mongoid2?
          index orderable_config[:column]
        else
          index(orderable_config[:column] => 1)
        end
      end
    end

    def orderable_field_opts
      field_opts = { :type => Integer }
      field_opts.merge!(orderable_config.slice(:as))
      field_opts
    end

  end
end
