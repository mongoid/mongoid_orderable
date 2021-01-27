# frozen_string_literal: true

module Mongoid
module Orderable
module Mixins
  module Callbacks
    extend ActiveSupport::Concern

    ORDERABLE_TRANSACTION_KEY = :__mongoid_orderable_in_txn

    included do
      before_create :orderable_before_create
      after_create :orderable_after_create, prepend: true
      before_update :orderable_before_update
      after_destroy :orderable_after_destroy, prepend: true

      delegate :before_create,
               :after_create,
               :before_update,
               :after_destroy,
               to: :orderable_handler,
               prefix: :orderable

      protected

      def orderable_handler
        @orderable_engine ||= if embedded?
                                Mongoid::Orderable::Handlers::Embedded.new(self)
                              else
                                Mongoid::Orderable::Handlers::Document.new(self)
                              end
      end
    end
  end
end
end
end
