# frozen_string_literal: true

module Mongoid
module Orderable
module Configs
  class GlobalConfig
    attr_accessor :column,
                  :index,
                  :scope,
                  :base,
                  :field_opts,
                  :use_transactions,
                  :transaction_max_retries

    def initialize
      self.column = :position
      self.index = true
      self.scope = nil
      self.base = 1
      self.field_opts = { type: Integer }
      self.use_transactions = false
      self.transaction_max_retries = 10
    end
  end
end
end
end
