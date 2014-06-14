module Mongoid
  module Orderable
    module Configurable

      attr_reader :configuration

      def default_configuration
        { :column => :position,
          :index => true,
          :scope => nil,
          :base => 1 }
      end

      def setup_orderable_class(options = {})
        @configuration = default_configuration;

        configuration.merge!(options) if options.is_a?(Hash)

        configure_orderable_scope

        define_orderable_scope

        generate_orderable_class_helpers
      end

      def configure_orderable_scope
        if configuration[:scope].is_a?(Symbol) && configuration[:scope].to_s !~ /_id$/
          scope_relation = self.relations[configuration[:scope].to_s]
          if scope_relation
            configuration[:scope] = scope_relation.key.to_sym
          else
            configuration[:scope] = "#{configuration[:scope]}_id".to_sym
          end
        elsif configuration[:scope].is_a?(String)
          configuration[:scope] = configuration[:scope].to_sym
        end
      end

      def define_orderable_scope
        case configuration[:scope]
        when Symbol then
          scope :orderable_scope, lambda { |document|
            where(configuration[:scope] => document.send(configuration[:scope])) }
        when Proc then
          scope :orderable_scope, configuration[:scope]
        else
          scope :orderable_scope, lambda { |document| where({}) }
        end
      end

      def generate_orderable_class_helpers
        self_class = self

        define_method :orderable_column do
          self_class.configuration[:column]
        end

        define_method :orderable_base do
          self_class.configuration[:base]
        end

        define_method :orderable_inherited_class do
          self_class if self_class.configuration[:inherited]
        end
      end

    end
  end
end
