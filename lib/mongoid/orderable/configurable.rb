module Mongoid
  module Orderable
    module Configurable

      def define_orderable_scope
        case orderable_config[:scope]
        when Symbol then
          scope :orderable_scope, lambda { |document|
            where(orderable_config[:scope] => document.send(orderable_config[:scope])) }
        when Proc then
          scope :orderable_scope, configuration[:scope]
        else
          scope :orderable_scope, lambda { |document| where({}) }
        end
      end

      def generate_orderable_class_helpers
        self_class = self

        define_method :orderable_column do
          self_class.orderable_config[:column]
        end

        define_method :orderable_base do
          self_class.orderable_config[:base]
        end

        define_method :orderable_inherited_class do
          self_class if self_class.orderable_config[:inherited]
        end
      end

    end
  end
end
