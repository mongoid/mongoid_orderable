# frozen_string_literal: true

module Mongoid
module Orderable
module Configs
  class FieldConfig
    CONFIG_OPTIONS = %i[field
                        scope
                        foreign_key
                        inherited
                        base
                        index
                        default
                        use_transactions
                        transaction_max_retries].freeze
    ALIASES = { column: :field }.freeze
    FIELD_OPTIONS = %i[as].freeze
    VALID_OPTIONS = (CONFIG_OPTIONS | FIELD_OPTIONS).freeze

    attr_reader :orderable_class,
                :options

    def initialize(parent, options = {})
      @orderable_class = parent
      assign_options(options)
      set_field_options
      set_orderable_scope
    end

    def global_config
      cfg = Mongoid::Orderable.config
      { field: cfg.field,
        index: cfg.index,
        base: cfg.base,
        field_opts: cfg.field_opts.dup,
        use_transactions: cfg.use_transactions,
        transaction_max_retries: cfg.transaction_max_retries }
    end

    protected

    def assign_options(options)
      @options = global_config
      return unless options.is_a?(Hash)
      @options.merge! options.symbolize_keys.transform_keys {|k| ALIASES[k] || k }.slice(*VALID_OPTIONS)
    end

    def set_field_options
      FIELD_OPTIONS.each do |key|
        next unless @options.key?(key)
        @options[:field_opts][key] = @options.delete(key)
      end
    end

    def set_orderable_scope
      return unless @options[:scope].class.in?([Array, Symbol, String])

      scope = Array(@options[:scope])
      scope.map! do |value|
        case value
        when Symbol
          relation = @orderable_class.relations[@options[:scope].to_s]&.key&.to_sym
          relation || value
        when String
          value.to_sym
        else
          raise ArgumentError.new("Orderable :scope invalid: #{@options[:scope]}")
        end
      end

      @options[:scope] = scope
    end
  end
end
end
end
