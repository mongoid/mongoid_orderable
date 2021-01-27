# frozen_string_literal: true

module Mongoid
module Orderable
module Handlers
  class DocumentTransactional < Document
    def before_create
      clear_all_positions
    end

    def after_create
      apply_all_positions
    end

    protected

    def apply_all_positions
      with_transaction { super }
    end

    def clear_all_positions
      orderable_keys.each {|field| doc.send("orderable_#{field}_position=", nil) }
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
