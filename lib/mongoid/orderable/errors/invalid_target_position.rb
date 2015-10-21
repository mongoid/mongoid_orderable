module Mongoid::Orderable
  module Errors
    class InvalidTargetPosition < Mongoid::Orderable::Errors::MongoidOrderableError
      def initialize value
        super _compose_message(value)
      end

      private
      def _compose_message value
        if ::Mongoid::Compatibility::Version.mongoid2?
          translate 'invalid_target_position', { :value => value.inspect }
        else
          compose_message 'invalid_target_position', { :value => value.inspect }
        end
      end
    end
  end
end
