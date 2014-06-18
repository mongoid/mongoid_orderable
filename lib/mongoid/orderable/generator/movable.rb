module Mongoid
  module Orderable
    module Generator
      module Movable

        def generate_movable_helpers(column_name)
          generate_move_to_helpers(column_name)
          generate_insert_at_helpers(column_name)
          generate_shorthand_helpers(column_name)
        end

        protected

        def generate_move_to_helpers(column_name)
          generate_method("move_#{column_name}_to") do |target_position|
            move_column_to column_name, target_position
          end

          generate_method("move_#{column_name}_to!") do |target_position|
            move_column_to column_name, target_position
            save
          end

          generate_method("move_#{column_name}_to=") do |target_position|
            move_column_to column_name, target_position
          end
        end

        def generate_insert_at_helpers(column_name)
          klass.class_eval do
            alias_method "insert_#{column_name}_at!", "move_#{column_name}_to!"
            alias_method "insert_#{column_name}_at",  "move_#{column_name}_to"
            alias_method "insert_#{column_name}_at=", "move_#{column_name}_to="
          end
        end

        def generate_shorthand_helpers(column_name)
          [:top, :bottom].each do |symbol|
            generate_method "move_#{column_name}_to_#{symbol}" do
              move_to column_name, symbol
            end

            generate_method "move_#{column_name}_to_#{symbol}!" do
              move_to! column_name, symbol
            end
          end

          [:higher, :lower].each do |symbol|
            generate_method "move_#{column_name}_#{symbol}" do
              move_to column_name, symbol
            end

            generate_method "move_#{column_name}_#{symbol}!" do
              move_to! column_name, symbol
            end
          end
        end

      end
    end
  end
end