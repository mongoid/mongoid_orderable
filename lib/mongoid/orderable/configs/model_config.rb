# frozen_string_literal: true

module Mongoid
module Orderable
module Configs
  class ModelConfig
    CONFIG_OPTIONS = %i[column
                        scope
                        foreign_key
                        inherited
                        base
                        index
                        default
                        use_transactions
                        transaction_max_retries].freeze
    FIELD_OPTIONS  = %i[as].freeze
    VALID_OPTIONS  = (CONFIG_OPTIONS | FIELD_OPTIONS).freeze

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
      { column: cfg.column,
        index: cfg.index,
        scope: cfg.scope,
        base: cfg.base,
        field_opts: cfg.field_opts.dup,
        use_transactions: cfg.use_transactions,
        transaction_max_retries: cfg.transaction_max_retries }
    end

    protected

    def assign_options(options)
      @options = global_config
      return unless options.is_a?(Hash)
      @options.merge! options.symbolize_keys.slice(*VALID_OPTIONS)
    end

    def set_field_options
      FIELD_OPTIONS.each do |key|
        next unless options.key? key
        @options[:field_opts][key] = options.delete(key)
      end
    end

    def set_orderable_scope
      if options[:scope].is_a?(Symbol) && options[:scope].to_s !~ /_id$/
        scope_relation = @orderable_class.relations[options[:scope].to_s]
        @options[:scope] = if scope_relation
                             scope_relation.key.to_sym
                           else
                             :"#{options[:scope]}_id"
                           end
      elsif options[:scope].is_a?(String)
        @options[:scope] = options[:scope].to_sym
      end
    end
  end
end
end
end
