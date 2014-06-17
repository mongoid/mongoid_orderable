module Mongoid
  module Orderable
    module Generator
      module Position

        def generate_position_helpers(column)
          klass.class_eval <<-eos
            def orderable_position(column = nil)
              column ||= default_orderable_column
              public_send "orderable_\#{column}_position"
            end
          eos

          generate_method("orderable_#{column}_position") do
            public_send column
          end

          generate_method("orderable_#{column}_position=") do |value|
            public_send "#{column}=", value
          end
        end

      end
    end
  end
end
