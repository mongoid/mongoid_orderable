# frozen_string_literal: true

module Mongoid
module Orderable
module Generators
  class Position < Base
    def generate(column_name)
      klass.class_eval <<~KLASS, __FILE__, __LINE__ + 1
        def orderable_position(column = nil)
          column ||= default_orderable_column
          send "orderable_\#{column}_position"
        end
      KLASS

      generate_method("orderable_#{column_name}_position") do
        send column_name
      end

      generate_method("orderable_#{column_name}_position=") do |value|
        send "#{column_name}=", value
      end
    end
  end
end
end
end
