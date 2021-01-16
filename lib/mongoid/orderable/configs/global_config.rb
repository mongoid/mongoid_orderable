# frozen_string_literal: true

module Mongoid
module Orderable
module Configs
  class GlobalConfig
    attr_accessor :field,
                  :index,
                  :base,
                  :field_opts,
                  :use_transactions,
                  :transaction_max_retries

    def initialize
      self.field = :position
      self.index = true
      self.base = 1
      self.field_opts = { type: Integer }
      self.use_transactions = false
      self.transaction_max_retries = 10
    end
  end
end
end
end
