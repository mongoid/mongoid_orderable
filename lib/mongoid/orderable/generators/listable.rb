# frozen_string_literal: true

module Mongoid
module Orderable
module Generators
  class Listable < Base
    def generate(column_name)
      generate_list_helpers(column_name)
      generate_aliased_helpers(column_name)
    end

    protected

    def generate_list_helpers(column_name)
      generate_method("next_#{column_name}_item") do
        next_item(column_name)
      end

      generate_method("next_#{column_name}_items") do
        next_items(column_name)
      end

      generate_method("previous_#{column_name}_item") do
        previous_item(column_name)
      end

      generate_method("previous_#{column_name}_items") do
        previous_items(column_name)
      end
    end

    def generate_aliased_helpers(column_name)
      klass.class_eval do
        alias_method "prev_#{column_name}_items", "previous_#{column_name}_items"
        alias_method "prev_#{column_name}_item",  "previous_#{column_name}_item"
      end
    end
  end
end
end
end
