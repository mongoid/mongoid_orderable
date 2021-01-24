# frozen_string_literal: true

module Mongoid
module Orderable
module Errors
  class TransactionFailed < ::Mongoid::Errors::MongoidError
    def initialize(error)
      super _compose_message(error)
    end

    private

    def _compose_message(error)
      compose_message 'transaction_failed'
      @summary = error.message
    end
  end
end
end
end
