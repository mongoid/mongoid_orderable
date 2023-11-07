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
      after_update :orderable_after_update, prepend: true
      after_destroy :orderable_after_destroy, prepend: true

      delegate :before_create,
               :after_create,
               :before_update,
               :after_update,
               :after_destroy,
               to: :orderable_handler,
               prefix: :orderable

      private

      def orderable_handler
        @orderable_handler ||= self.class.orderable_handler_class.new(self)
      end

      def self.orderable_handler_class
        if embedded?
          Mongoid::Orderable::Handlers::DocumentEmbedded
        elsif orderable_configs.values.any? {|c| c[:use_transactions] }
          Mongoid::Orderable::Handlers::DocumentTransactional
        else
          Mongoid::Orderable::Handlers::Document
        end
      end
    end
  end
end
end
end
