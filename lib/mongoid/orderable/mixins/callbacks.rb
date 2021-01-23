# frozen_string_literal: true

module Mongoid
module Orderable
module Mixins
  module Callbacks
    extend ActiveSupport::Concern

    ORDERABLE_TRANSACTION_KEY = :__mongoid_orderable_in_txn

    included do
      around_save :orderable_update_positions
      after_destroy :orderable_remove_positions

      protected

      # For new records, or if the orderable scope changes,
      # we must yield the save action inside the transaction.
      def orderable_update_positions(&_block)
        any_scope_changed = false
        with_orderable_transaction do
          any_scope_changed = orderable_keys.map do |field|
            orderable_apply_one_position(field, move_all[field])
          end.any? || new_record?
          yield if any_scope_changed
        end
        yield unless any_scope_changed
      end

      def orderable_remove_positions
        orderable_keys.each do |field|
          orderable_remove_one_position(field)
        end
      end

      # Returns boolean value as follows:
      # - true: The document is persisted and its orderable scope was changed.
      #         Document#save must be performed transactionally.
      # - false: Document#save does not need to be performed transactionally.
      def orderable_apply_one_position(field, target_position)
        orderable_set_lock(field) if orderable_use_transactions && !embedded?

        f = orderable_field(field)
        scope = orderable_scope(field)
        scope_changed = orderable_scope_changed?(field)

        # Set scope-level lock if scope changed
        if orderable_use_transactions && persisted? && !embedded? && scope_changed
          orderable_set_lock(field, true)
          scope_changed = orderable_scope_changed?(field)
        end

        # Get the current position as exists in the database
        current = if !persisted? || scope_changed
                    nil
                  elsif persisted? && !embedded?
                    scope.where(_id: _id).pluck(f).first
                  else
                    orderable_position(field)
                  end

        # If scope changed, remove the position from the old scope
        if persisted? && !embedded? && scope_changed
          existing_doc = self.class.unscoped.find(_id)
          existing_doc.orderable_remove_one_position(field)
        end

        # Return if there is no instruction to change the position
        in_list = persisted? && current
        return false if in_list && !target_position

        # Use $inc operator to shift the position of the other documents
        target = resolve_target_position(field, target_position, in_list)
        if !in_list
          scope.gte(f => target).inc(f => 1)
        elsif target < current
          scope.where(f => { '$gte' => target, '$lt' => current }).inc(f => 1)
        elsif target > current
          scope.where(f => { '$gt' => current, '$lte' => target }).inc(f => -1)
        end

        # If persisted, update the field in the database atomically
        set(f => target) if persisted? && !embedded?
        send("orderable_#{field}_position=", target)

        # Return value indicates whether Document#save must be
        # performed transactionally
        scope_changed
      end

      def orderable_remove_one_position(field)
        f = orderable_field(field)
        current = orderable_position(field)
        orderable_set_lock(field) if orderable_use_transactions && !embedded?
        orderable_scope(field).gt(f => current).inc(f => -1)
      end

      def resolve_target_position(field, target_position, in_list)
        target_position ||= 'bottom'

        unless target_position.is_a? Numeric
          target_position = case target_position.to_s
                            when 'top' then (min ||= orderable_top(field))
                            when 'bottom' then (max ||= orderable_bottom(field, in_list))
                            when 'higher' then orderable_position(field).pred
                            when 'lower' then orderable_position(field).next
                            when /\A\d+\Z/ then target_position.to_i
                            else raise Mongoid::Orderable::Errors::InvalidTargetPosition.new(target_position)
                            end
        end

        if target_position <= (min ||= orderable_top(field))
          target_position = min
        elsif target_position > (max ||= orderable_bottom(field, in_list))
          target_position = max
        end

        target_position
      end

      def orderable_set_lock(field, scope_changed = false)
        return unless orderable_use_transactions && !embedded?
        model_name = self.class.orderable_configs[field][:lock_collection].to_s.singularize.classify
        model = Mongoid::Orderable::Models.const_get(model_name)
        doc = orderable_lock_scope(field, scope_changed)
        model.where(doc).find_one_and_update(doc, { upsert: true })
      end

      def orderable_lock_scope(field, scope_changed = false)
        sel = orderable_scope(field).selector
        scope = ([collection_name] + (scope_changed ? sel.keys : sel.to_a.flatten)).map(&:to_s).join('|')
        { scope: scope }
      end

      def orderable_use_transactions
        orderable_keys.any? {|k| self.class.orderable_configs[k][:use_transactions] }
      end

      def orderable_transaction_max_retries
        orderable_keys.map {|k| self.class.orderable_configs[k][:transaction_max_retries] }.compact.max
      end

      def with_orderable_transaction(&_block)
        Mongoid::QueryCache.uncached do
          if orderable_use_transactions && !Thread.current[ORDERABLE_TRANSACTION_KEY]
            Thread.current[ORDERABLE_TRANSACTION_KEY] = true
            retries = orderable_transaction_max_retries
            begin
              self.class.with_session(causal_consistency: true) do |session|
                session.start_transaction(read: { mode: :primary },
                                          read_concern: { level: 'majority' },
                                          write_concern: { w: 'majority' })
                yield
                session.commit_transaction
              end
            rescue Mongo::Error::OperationFailure => e
              sleep(0.001)
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
