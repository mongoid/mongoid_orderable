# frozen_string_literal: true

module Mongoid
module Orderable
module Mixins
  module Callbacks
    extend ActiveSupport::Concern

    ORDERABLE_TRANSACTION_KEY = :__mongoid_orderable_in_txn

    included do
      around_save :orderable_update_positions
      after_destroy :orderable_remove_positions, unless: -> { embedded? && _root.destroyed? }

      delegate :update_positions,
               :remove_positions,
               to: :orderable_engine,
               prefix: :orderable

      protected

      def orderable_engine
        @orderable_engine ||= Mongoid::Orderable::Engine.new(self)
      end
    end
  end
end
end
end
