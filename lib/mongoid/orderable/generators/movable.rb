# frozen_string_literal: true

module Mongoid
module Orderable
module Generators
  class Movable < Base
    def generate(field_name)
      generate_move_to_helpers(field_name)
      generate_insert_at_helpers(field_name)
      generate_shorthand_helpers(field_name)
    end

    protected

    def generate_move_to_helpers(field_name)
      generate_method("move_#{field_name}_to") do |target_position|
        move_field_to target_position, field: field_name
      end

      generate_method("move_#{field_name}_to!") do |target_position|
        move_field_to target_position, field: field_name
        save
      end

      generate_method("move_#{field_name}_to=") do |target_position|
        move_field_to target_position, field: field_name
      end
    end

    def generate_insert_at_helpers(field_name)
      klass.class_eval do
        alias_method "insert_#{field_name}_at!", "move_#{field_name}_to!"
        alias_method "insert_#{field_name}_at",  "move_#{field_name}_to"
        alias_method "insert_#{field_name}_at=", "move_#{field_name}_to="
      end
    end

    def generate_shorthand_helpers(field_name)
      %i[top bottom].each do |symbol|
        generate_method "move_#{field_name}_to_#{symbol}" do
          move_to symbol, field: field_name
        end

        generate_method "move_#{field_name}_to_#{symbol}!" do
          move_to! symbol, field: field_name
        end
      end

      %i[higher lower].each do |symbol|
        generate_method "move_#{field_name}_#{symbol}" do
          move_to symbol, field: field_name
        end

        generate_method "move_#{field_name}_#{symbol}!" do
          move_to! symbol, field: field_name
        end
      end
    end
  end
end
end
end
