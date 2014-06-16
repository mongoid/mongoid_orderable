module Mongoid
  module Orderable
    class OrderableClass

      attr_reader :klass, :configuration

      def initialize klass, configuration
        @klass = klass
        @configuration = configuration
      end

      def setup
        add_db_field
        add_db_index if configuration[:index]
        save_configuration
      end

      def self.setup(klass, configuration={})
        new(klass, configuration).setup
      end

      protected

      def add_db_field
        klass.field configuration[:column], configuration[:field_opts]
      end

      def add_db_index
        if MongoidOrderable.mongoid2?
          klass.index configuration[:column]
        else
          klass.index(configuration[:column] => 1)
        end
      end

      def save_configuration
        klass.orderable_configurations ||= {}
        klass.orderable_configurations[configuration[:column]] = configuration
      end

    end
  end
end