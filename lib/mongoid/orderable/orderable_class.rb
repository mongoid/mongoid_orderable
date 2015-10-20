module Mongoid
  module Orderable
    class OrderableClass
      include Mongoid::Orderable::Generator

      attr_reader :klass, :configuration

      def initialize klass, configuration
        @klass = klass
        @configuration = configuration
      end

      def setup
        add_db_field
        add_db_index if configuration[:index]
        save_configuration
        generate_all_helpers
        add_callbacks
      end

      def self.setup(klass, configuration={})
        new(klass, configuration).setup
      end

      protected

      def add_db_field
        klass.field configuration[:column], configuration[:field_opts]
      end

      def add_db_index
        spec = [[configuration[:column], 1]]
        spec.unshift([configuration[:scope], 1]) if configuration[:scope].is_a?(Symbol)
        if ::Mongoid::Compatibility::Version.mongoid2?
          klass.index(spec)
        else
          klass.index(Hash[spec])
        end
      end

      def save_configuration
        klass.orderable_configurations ||= {}
        klass.orderable_configurations = klass.orderable_configurations.merge(column_name => configuration)
      end

      def add_callbacks
        klass.add_orderable_callbacks
      end
    end
  end
end
