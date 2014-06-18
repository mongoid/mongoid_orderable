module Mongoid
  module Orderable
    module Generator
      module Listable

        def generate_listable_helpers(column)
          generate_list_helpers(column)
          generate_aliased_helpers(column)
        end

        protected

        def generate_list_helpers(column)
          generate_method("next_#{column}_item") do
            next_item(column)
          end

          generate_method("next_#{column}_items") do
            next_items(column)
          end

          generate_method("previous_#{column}_item") do
            previous_item(column)
          end

          generate_method("previous_#{column}_items") do
            previous_items(column)
          end
        end

        def generate_aliased_helpers(column)
          klass.class_eval do
            alias_method "prev_#{column}_items", "previous_#{column}_items"
            alias_method "prev_#{column}_item",  "previous_#{column}_item"
          end
        end

      end
    end
  end
end
