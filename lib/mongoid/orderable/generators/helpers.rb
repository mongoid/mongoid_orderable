# frozen_string_literal: true

module Mongoid
module Orderable
module Generators
  class Helpers < Base
    def generate
      self_class = klass

      klass.class_eval <<~KLASS, __FILE__, __LINE__ + 1
        def orderable_top(column = nil)
          column ||= default_orderable_column
          #{self_class}.orderable_configs[column][:base]
        end

        def orderable_column(column = nil)
          column ||= default_orderable_column
          #{self_class}.orderable_configs[column][:column]
        end
      KLASS

      generate_method(:orderable_inherited_class) do
        self_class.orderable_configs.any? {|_col, conf| conf[:inherited] } ? self_class : self.class
      end
    end
  end
end
end
end
