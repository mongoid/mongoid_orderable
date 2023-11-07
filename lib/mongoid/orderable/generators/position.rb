# frozen_string_literal: true

module Mongoid
module Orderable
module Generators
  class Position < Base
    def generate(field_name)
      klass.class_eval <<~KLASS, __FILE__, __LINE__ + 1
        def orderable_position(field = nil)
          field ||= default_orderable_field
          send("orderable_\#{field}_position")
        end

        def orderable_position_was(field = nil)
          field ||= default_orderable_field
          send("orderable_\#{field}_position_was")
        end
      KLASS

      generate_method("orderable_#{field_name}_position") do
        send(field_name)
      end

      generate_method("orderable_#{field_name}_position_was") do
        send("#{field_name}_was")
      end

      generate_method("orderable_#{field_name}_position=") do |value|
        send("#{field_name}=", value)
      end
    end
  end
end
end
end
