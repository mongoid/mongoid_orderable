# frozen_string_literal: true

module Mongoid
module Orderable
module Generators
  class Scope < Base
    def generate(field_name, order_scope)
      criteria = criteria(order_scope)
      klass.class_eval do
        scope "orderable_#{field_name}_scope", criteria
      end
    end

    private

    def criteria(order_scope)
      case order_scope
      when Proc then order_scope
      when Array then ->(doc) { where(order_scope.each_with_object({}) {|f, h| h[f] = doc.send(f) }) }
      else ->(_doc) { where({}) }
      end
    end
  end
end
end
end
