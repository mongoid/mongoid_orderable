module Mongoid
  module Orderable
    module Generator
      module Movable

        def generate_movable_helpers(column)
          generate_move_to_helpers(column)
          generate_insert_at_helpers(column)
          generate_shorthand_helpers(column)
        end

        protected

        def generate_move_to_helpers(column)
          generate_method("move_#{column}_to") do |target_position|
            move_column_to column, target_position
          end

          generate_method("move_#{column}_to!") do |target_position|
            move_column_to column, target_position
            save
          end

          generate_method("move_#{column}_to=") do |target_position|
            move_column_to column, target_position
          end
        end

        def generate_insert_at_helpers(column)
          klass.class_eval do
            alias_method "insert_#{column}_at!", "move_#{column}_to!"
            alias_method "insert_#{column}_at",  "move_#{column}_to"
            alias_method "insert_#{column}_at=", "move_#{column}_to="
          end
        end

        def generate_shorthand_helpers(column)
          [:top, :bottom].each do |symbol|
            generate_method "move_#{column}_to_#{symbol}" do
              move_to column, symbol
            end

            generate_method "move_#{column}_to_#{symbol}!" do
              move_to! column, symbol
            end
          end

          [:higher, :lower].each do |symbol|
            generate_method "move_#{column}_#{symbol}" do
              move_to column, symbol
            end

            generate_method "move_#{column}_#{symbol}!" do
              move_to! column, symbol
            end
          end
        end

      end
    end
  end
end