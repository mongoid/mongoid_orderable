# frozen_string_literal: true

module Mongoid
module Orderable
module Generators
  class Scope < Base
    def generate(column_name, order_scope)
      klass.class_eval do
        criteria = case order_scope
                   when Symbol then ->(document) { where(order_scope => document.send(order_scope)) }
                   when Proc   then order_scope
                   else ->(_document) { where({}) }
                   end
        scope "orderable_#{column_name}_scope", criteria
      end
    end
  end
end
end
end
