module Mongoid::Orderable
  extend ActiveSupport::Concern

  included do
    include Mongoid::Orderable::Configurable
    include Mongoid::Orderable::Movable
    include Mongoid::Orderable::Listable
  end

  module ClassMethods

    def orderable options = {}
      configuration = {
        :column => :position,
        :index => true,
        :scope => nil,
        :base => 1
      }

      configuration.merge! options if options.is_a?(Hash)

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

      field configuration[:column], orderable_field_opts(configuration)
      if configuration[:index]
        if MongoidOrderable.mongoid2?
          index configuration[:column]
        else
          index(configuration[:column] => 1)
        end
      end

      case configuration[:scope]
      when Symbol then
        scope :orderable_scope, lambda { |document|
          where(configuration[:scope] => document.send(configuration[:scope])) }
      when Proc then
        scope :orderable_scope, configuration[:scope]
      else
        scope :orderable_scope, lambda { |document| where({}) }
      end

      define_method :orderable_column do
        configuration[:column]
      end

      define_method :orderable_base do
        configuration[:base]
      end

      self_class = self
      define_method :orderable_inherited_class do
        self_class if configuration[:inherited]
      end

      before_save :add_to_list
      after_destroy :remove_from_list
    end

    private

    def orderable_field_opts(configuration)
      field_opts = { :type => Integer }
      field_opts.merge!(configuration.slice(:as))
      field_opts
    end
  end
end
