# frozen_string_literal: true

module Mongoid
module Orderable
module Handlers
  class DocumentTransactional < Document
    def before_create
      set_target_positions
    end

    def after_create
      apply_all_positions
      super
    end

    private

    def apply_all_positions
      with_transaction { super }
    end

    def use_transactions
      true
    end

    def with_transaction(&block)
      Mongoid::Orderable::Handlers::Transaction.new(doc).with_transaction(&block)
    end
  end
end
end
end
