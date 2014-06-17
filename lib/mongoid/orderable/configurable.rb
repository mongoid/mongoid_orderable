module Mongoid
  module Orderable
    module Configurable

      def define_orderable_scope(column, order_scope)
        class_eval do
          scope "orderable_#{column}_scope", case order_scope
                                           when Symbol then lambda { |document| where(order_scope => document.send(order_scope)) }
                                           when Proc   then order_scope
                                           else lambda { |document| where({}) }
                                           end
        end
      end

      def define_position_helpers(column_key)
        class_eval <<-eos
          def orderable_position(column = nil)
            column ||= default_orderable_column
            public_send("orderable_\#{column}_position")
          end

          def orderable_#{column_key}_position
            public_send '#{column_key}'
          end

          def orderable_#{column_key}_position=(value)
            public_send '#{column_key}=', value
          end
        eos
      end

      def generate_orderable_class_helpers
        self_class = self

        define_method :orderable_base do |column = nil|
          column ||= default_orderable_column
          self_class.orderable_configurations[column][:base]
        end

        define_method :orderable_inherited_class do
          self_class.orderable_configurations.any?{ |col, conf| conf[:inherited] } ? self_class : self.class
        end
      end

    end
  end
end
