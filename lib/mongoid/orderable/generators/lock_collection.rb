# frozen_string_literal: true

module Mongoid
module Orderable
module Generators
  class LockCollection
    def generate(collection_name)
      return unless collection_name
      model_name = collection_name.to_s.singularize.classify
      return if model_exists?(model_name)
      ::Mongoid::Orderable.class_eval <<~KLASS, __FILE__, __LINE__ + 1
        module Models
          class #{model_name}
            include Mongoid::Document

            store_in collection: :#{collection_name}

            field :scope, type: String

            index({ scope: 1 }, { unique: 1 })
          end
        end
      KLASS
    end

    protected

    def model_exists?(model_name)
      base = ::Mongoid::Orderable::Models
      !!(defined?(base) && base.const_get(model_name))
    rescue NameError
      false
    end
  end
end
end
end
