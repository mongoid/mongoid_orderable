module Mongoid
  module Orderable
    class Configuration

      CONFIG_OPTIONS = %w(column scope foreign_key inherited base index default).map(&:to_sym)
      FIELD_OPTIONS  = %w(as).map(&:to_sym)
      VALID_OPTIONS  = CONFIG_OPTIONS + FIELD_OPTIONS

      attr_reader :orderable_class, :options

      def initialize(parent, options = {})
        @orderable_class = parent
        set_options(options)
        set_field_options
        set_orderable_scope
      end

      def default_configuration
        { column: :position,
          index: true,
          scope: nil,
          base: 1,
          field_opts: { type: Integer }}
      end

      def self.build(parent, options = {})
        new(parent, options).options
      end

      protected

      def set_options(options)
        @options = default_configuration
        return unless options.is_a? Hash
        @options.merge! options.symbolize_keys.slice(*VALID_OPTIONS)
      end

      def set_field_options
        FIELD_OPTIONS.each do |key|
          next unless options.has_key? key
          @options[:field_opts][key] = options.delete(key)
        end
      end

      def set_orderable_scope
        if options[:scope].is_a?(Symbol) && options[:scope].to_s !~ /_id$/
          scope_relation = @orderable_class.relations[options[:scope].to_s]
          if scope_relation
            @options[:scope] = scope_relation.key.to_sym
          else
            @options[:scope] = "#{options[:scope]}_id".to_sym
          end
        elsif options[:scope].is_a?(String)
          @options[:scope] = options[:scope].to_sym
        end
      end

    end
  end
end
