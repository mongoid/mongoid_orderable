# frozen_string_literal: true

module Mongoid
module Orderable
module Mixins
  module Callbacks
    extend ActiveSupport::Concern

    ORDERABLE_TRANSACTION_KEY = :__mongoid_orderable_in_txn

    included do
      around_save :orderable_apply_positions
      after_destroy :orderable_remove_positions

      protected

      # If the scope of the orderable changes, it is necessary to ensure
      # that both the new position and the
      def orderable_apply_positions(&_block)
        any_scope_changed = false
        with_orderable_transaction do
          any_scope_changed = orderable_keys.map do |column|
            orderable_apply_one_position(column, move_all[column])
          end.any?
          yield if any_scope_changed
        end
        yield unless any_scope_changed
      end

      def orderable_remove_positions
        orderable_keys.each do |column|
          orderable_remove_one_position(column)
        end
      end

      # Returns boolean value as follows:
      # - true: The document is persisted and its orderable scope was changed.
      #         Document#save must be performed transactionally.
      # - false: Document#save does not need to be performed transactionally.
      def orderable_apply_one_position(column, target_position, &_block)
        col = orderable_column(column)
        target = resolve_target_position(column, target_position)
        scope = orderable_scope(column)
        scope_changed = orderable_scope_changed?(column)

        current = if scope_changed
                    nil
                  elsif persisted? && !embedded?
                    scope.where(_id: _id).pluck(col).first
                  else
                    orderable_position(column)
                  end

        # Return if there is no instruction to change the position
        in_list = persisted? && current
        return false if in_list && !target_position

        if persisted? && !embedded? && scope_changed
          existing_doc = self.class.unscoped.find(_id)
          existing_doc.orderable_remove_one_position(column)
        end

        if !in_list
          scope.gte(col => target).inc(col => 1)
        elsif target < current
          scope.where(col => { '$gte' => target, '$lt' => current }).inc(col => 1)
        elsif target > current
          scope.where(col => { '$gt' => current, '$lte' => target }).inc(col => -1)
        end

        set(col => target) if persisted?
        send("orderable_#{column}_position=", target)

        # Indicates whether Document#save must be performed transactionally
        persisted? && scope_changed
      end

      def orderable_remove_one_position(column)
        col = orderable_column(column)
        current = orderable_position(column)
        orderable_scope(column).gt(col => current).inc(col => -1)
      end

      def resolve_target_position(column, target_position)
        target_position ||= 'bottom'

        unless target_position.is_a? Numeric
          target_position = case target_position.to_s
                            when 'top' then (min ||= orderable_top(column))
                            when 'bottom' then (max ||= orderable_bottom(column))
                            when 'higher' then orderable_position(column).pred
                            when 'lower' then orderable_position(column).next
                            when /\A\d+\Z/ then target_position.to_i
                            else raise Mongoid::Orderable::Errors::InvalidTargetPosition.new(target_position)
                            end
        end

        if target_position <= (min ||= orderable_top(column))
          target_position = min
        elsif target_position > (max ||= orderable_bottom(column))
          target_position = max
        end

        target_position
      end

      def use_transactions
        true
      end

      def transaction_max_retries
        10
      end

      def with_orderable_transaction(&_block)
        Mongoid::QueryCache.uncached do
          if use_transactions && !Thread.current[ORDERABLE_TRANSACTION_KEY]
            Thread.current[ORDERABLE_TRANSACTION_KEY] = true
            retries = transaction_max_retries
            begin
              self.class.with_session(causal_consistency: true) do |session|
                session.start_transaction(read: { mode: :primary },
                                          read_concern: { level: 'majority' },
                                          write_concern: { w: 'majority' })
                yield
                session.commit_transaction
              end
            rescue Mongo::Error::OperationFailure => e
              retries -= 1
              retry if retries >= 0
              raise Mongoid::Orderable::Errors::TransactionFailed.new(e)
            ensure
              Thread.current[ORDERABLE_TRANSACTION_KEY] = nil
            end
          else
            yield
          end
        end
      end
    end
  end
end
end
end
