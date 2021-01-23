# frozen_string_literal: true

module Mongoid
module Orderable
  class Installer
    attr_reader :klass, :config

    def initialize(klass, options = {})
      @klass = klass
      @config = Mongoid::Orderable::Configs::FieldConfig.new(klass, options).options
    end

    def setup
      add_db_field
      add_db_index if config[:index]
      save_config
      include_mixins
      generate_all_helpers
    end

    protected

    def field_name
      config[:field_opts][:as] || config[:field]
    end

    def order_scope
      config[:scope]
    end

    def add_db_field
      klass.field(config[:field], { type: Integer }.reverse_merge(config[:field_opts]))
    end

    def add_db_index
      spec = [[config[:field], 1]]
      config[:scope].each {|field| spec.unshift([field, 1]) } if config[:scope].is_a?(Array)
      klass.index(Hash[spec])
    end

    def save_config
      klass.orderable_configs ||= {}
      klass.orderable_configs = klass.orderable_configs.merge(field_name => config)
    end

    def include_mixins
      klass.send :include, Mixins::Helpers
      klass.send :include, Mixins::Callbacks
      klass.send :include, Mixins::Movable
      klass.send :include, Mixins::Listable
    end

    def generate_all_helpers
      Generators::Scope.new(klass).generate(field_name, order_scope)
      Generators::Position.new(klass).generate(field_name)
      Generators::Movable.new(klass).generate(field_name)
      Generators::Listable.new(klass).generate(field_name)
      Generators::Helpers.new(klass).generate
      Generators::LockCollection.new.generate(config[:lock_collection])
    end
  end
end
end
