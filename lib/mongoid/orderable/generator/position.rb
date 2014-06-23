module Mongoid
  module Orderable
    module Generator
      module Position

        def generate_position_helpers(column_name)
          klass.class_eval <<-eos
            def orderable_position(column = nil)
              column ||= default_orderable_column
              send "orderable_\#{column}_position"
            end
          eos

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
