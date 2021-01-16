# frozen_string_literal: true

module Mongoid
module Orderable
module Mixins
  module Callbacks
    extend ActiveSupport::Concern

    ORDERABLE_TRANSACTION_KEY = :__mongoid_orderable_in_txn

    included do
      before_save :add_to_list
      after_destroy :remove_from_list

      protected

      def add_to_list
        orderable_keys.each do |column|
          apply_position(column, move_all[column])
        end
      end

      def remove_from_list
        orderable_keys.each do |column|
          remove_position_from_list(column)
        end
      end

      def remove_position_from_list(column)
        col = orderable_column(column)
        pos = orderable_position(column)
        orderable_scope(column).where(col.gt => pos).inc(col => -1)
      end

      def apply_position(column, target_position)
        with_orderable_transaction do
          if persisted? && !embedded? && orderable_scope_changed?(column)
            self.class.unscoped.find(_id).remove_position_from_list(column)
            set(column => nil)
          end

          return if !target_position && in_list?(column)

          target_position = resolve_target_position(column, target_position)
          scope = orderable_scope(column)
          col = orderable_column(column)
          if persisted? && !embedded?
            pos = self.class.unscoped.find(_id).send(col)
          else
            pos = orderable_position(column)
          end

          if !in_list?(column)
            scope.gte(col => target_position).inc(col => 1)
          elsif target_position < pos
            scope.where(col.gte => target_position, col.lt => pos).inc(col => 1)
          elsif target_position > pos
            scope.where(col.gt => pos, col.lte => target_position).inc(col => -1)
          end

          if persisted?
            set(column => target_position)
          else
            send("orderable_#{column}_position=", target_position)
          end
        end
      end

      def resolve_target_position(column, target_position)
        target_position ||= :bottom

        unless target_position.is_a? Numeric
          target_position = case target_position.to_s
                            when 'top' then orderable_base(column)
                            when 'bottom' then bottom_orderable_position(column)
                            when 'higher' then orderable_position(column).pred
                            when 'lower' then orderable_position(column).next
                            when /\A\d+\Z/ then target_position.to_i
                            else raise Mongoid::Orderable::Errors::InvalidTargetPosition, target_position
                            end
        end

        target_position = orderable_base(column) if target_position < orderable_base(column)
        target_position = bottom_orderable_position(column) if target_position > bottom_orderable_position(column)
        target_position
      end

      def use_transactions
        true
      end

      def transaction_max_retries
        10
      end

      def with_orderable_transaction(&_block)
        if use_transactions && !Thread.current[ORDERABLE_TRANSACTION_KEY]
          retries = transaction_max_retries
          begin
            self.class.with_session do |session|
              session.start_transaction(read: { mode: :primary },
                                        read_concern: { level: :local },
                                        write_concern: { w: 1 })
              yield
              session.commit_transaction
            end
          rescue Mongo::Error::OperationFailure => _e
            retries -= 1
            retry if retries >= 0
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
