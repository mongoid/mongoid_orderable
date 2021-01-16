# frozen_string_literal: true

module Mongoid
module Orderable
module Errors
  class InvalidTargetPosition < ::Mongoid::Errors::MongoidError
    def initialize(value)
      super _compose_message(value)
    end

    private

    def _compose_message(value)
      compose_message 'invalid_target_position', value: value.inspect
    end
  end
end
end
end
