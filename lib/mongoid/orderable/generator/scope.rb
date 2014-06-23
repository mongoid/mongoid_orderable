module Mongoid
  module Orderable
    module Generator
      module Scope
        def generate_scope_helpers(column_name, order_scope)
          klass.class_eval do
            scope "orderable_#{column_name}_scope", case order_scope
                                                    when Symbol then lambda { |document| where(order_scope => document.send(order_scope)) }
                                                    when Proc   then order_scope
                                                    else lambda { |document| where({}) }
                                                    end
          end
        end
      end
    end
  end
end