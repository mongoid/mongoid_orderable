# frozen_string_literal: true

module Mongoid
module Orderable
module Generators
  class Base
    attr_reader :klass

    def initialize(klass)
      @klass = klass
    end

    protected

    def generate_method(name, &block)
      klass.send(:define_method, name, &block)
    end
  end
end
end
end
