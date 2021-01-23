# frozen_string_literal: true

module Mongoid
module Orderable
module Configs
  class GlobalConfig
    attr_accessor :field,
                  :as,
                  :base,
                  :index,
                  :use_transactions,
                  :transaction_max_retries,
                  :lock_collection

    def initialize
      self.field = :position
      self.index = true
      self.base = 1
      self.use_transactions = false
      self.transaction_max_retries = 10
      self.lock_collection = :mongoid_orderable_locks
    end
  end
end
end
end
