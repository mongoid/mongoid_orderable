module Mongoid
  module Orderable
    module Generator
      module Helpers

        def generate_orderable_helpers
          self_class = klass

          klass.class_eval <<-eos
            def orderable_base(column = nil)
              column ||= default_orderable_column
              #{self_class}.orderable_configurations[column][:base]
            end

            def orderable_column(column = nil)
              column ||= default_orderable_column
              #{self_class}.orderable_configurations[column][:column]
            end
          eos

          generate_method(:orderable_inherited_class) do
            self_class.orderable_configurations.any?{ |col, conf| conf[:inherited] } ? self_class : self.class
          end
        end

      end
    end
  end
end