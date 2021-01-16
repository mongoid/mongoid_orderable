# frozen_string_literal: true

module Mongoid
module Orderable
module Generators
  class Helpers < Base
    def generate
      self_class = klass

      klass.class_eval <<~KLASS, __FILE__, __LINE__ + 1
        def orderable_top(field = nil)
          field ||= default_orderable_field
          #{self_class}.orderable_configs[field][:base]
        end

        def orderable_field(field = nil)
          field ||= default_orderable_field
          #{self_class}.orderable_configs[field][:field]
        end
      KLASS

      generate_method(:orderable_inherited_class) do
        self_class.orderable_configs.any? {|_field, conf| conf[:inherited] } ? self_class : self.class
      end
    end
  end
end
end
end
