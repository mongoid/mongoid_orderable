module Mongoid
  module Orderable
    module Configurable

      attr_reader :orderable_config

      def default_orderable_config
        { :column => :position,
          :index => true,
          :scope => nil,
          :base => 1 }
      end

      def setup_orderable_class(options = {})
        @orderable_config = default_orderable_config;

        orderable_config.merge!(options) if options.is_a?(Hash)

        configure_orderable_scope

        define_orderable_scope

        generate_orderable_class_helpers
      end

      def configure_orderable_scope
        if orderable_config[:scope].is_a?(Symbol) && orderable_config[:scope].to_s !~ /_id$/
          scope_relation = self.relations[orderable_config[:scope].to_s]
          if scope_relation
            orderable_config[:scope] = scope_relation.key.to_sym
          else
            orderable_config[:scope] = "#{orderable_config[:scope]}_id".to_sym
          end
        elsif orderable_config[:scope].is_a?(String)
          orderable_config[:scope] = orderable_config[:scope].to_sym
        end
      end

      def define_orderable_scope
        case orderable_config[:scope]
        when Symbol then
          scope :orderable_scope, lambda { |document|
            where(orderable_config[:scope] => document.send(orderable_config[:scope])) }
        when Proc then
          scope :orderable_scope, orderable_config[:scope]
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
