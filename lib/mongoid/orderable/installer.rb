# frozen_string_literal: true

module Mongoid
module Orderable
  class Installer
    attr_reader :klass, :config

    def initialize(klass, options = {})
      @klass = klass
      @config = Mongoid::Orderable::Configs::ModelConfig.new(klass, options).options
    end

    def setup
      add_db_field
      add_db_index if config[:index]
      save_config
      include_mixins
      generate_all_helpers
    end

    protected

    def column_name
      config[:field_opts][:as] || config[:column]
    end

    def order_scope
      config[:scope]
    end

    def add_db_field
      klass.field(config[:column], config[:field_opts])
    end

    def add_db_index
      spec = [[config[:column], 1]]
      spec.unshift([config[:scope], 1]) if config[:scope].is_a?(Symbol)
      klass.index(Hash[spec])
    end

    def save_config
      klass.orderable_configs ||= {}
      klass.orderable_configs = klass.orderable_configs.merge(column_name => config)
    end

    def include_mixins
      klass.send :include, Mixins::Helpers
      klass.send :include, Mixins::Callbacks
      klass.send :include, Mixins::Movable
      klass.send :include, Mixins::Listable
    end

    def generate_all_helpers
      Generators::Scope.new(klass).generate(column_name, order_scope)
      Generators::Position.new(klass).generate(column_name)
      Generators::Movable.new(klass).generate(column_name)
      Generators::Listable.new(klass).generate(column_name)
      Generators::Helpers.new(klass).generate
    end
  end
end
end
