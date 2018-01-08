module Mongoid::Orderable
  module Errors
    class InvalidTargetPosition < Mongoid::Orderable::Errors::MongoidOrderableError

      def initialize value
        super _compose_message(value)
      end

      private

      def _compose_message value
        compose_message 'invalid_target_position', { value: value.inspect }
      end
    end
  end
end
