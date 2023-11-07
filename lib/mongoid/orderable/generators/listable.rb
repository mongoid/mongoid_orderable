# frozen_string_literal: true

module Mongoid
module Orderable
module Generators
  class Listable < Base
    def generate(field_name)
      generate_list_helpers(field_name)
      generate_aliased_helpers(field_name)
    end

    private

    def generate_list_helpers(field_name)
      generate_method("next_#{field_name}_item") do
        next_item(field_name)
      end

      generate_method("next_#{field_name}_items") do
        next_items(field_name)
      end

      generate_method("previous_#{field_name}_item") do
        previous_item(field_name)
      end

      generate_method("previous_#{field_name}_items") do
        previous_items(field_name)
      end
    end

    def generate_aliased_helpers(field_name)
      klass.class_eval do
        alias_method "prev_#{field_name}_items", "previous_#{field_name}_items"
        alias_method "prev_#{field_name}_item",  "previous_#{field_name}_item"
      end
    end
  end
end
end
end
