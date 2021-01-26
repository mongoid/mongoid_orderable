# frozen_string_literal: true

module Mongoid
module Orderable
  class Engine
    ORDERABLE_TRANSACTION_KEY = :__mongoid_orderable_in_txn

    attr_accessor :doc

    def initialize(doc)
      @doc = doc
    end

    # For new records, or if the orderable scope changes,
    # we must yield the save action inside the transaction.
    def update_positions(&_block)
      yield and return unless orderable_keys.any? {|field| changed?(field) }

      new_record = new_record?
      with_transaction do
        orderable_keys.map {|field| apply_one_position(field, move_all[field]) }
        yield if new_record
      end

      yield unless new_record
    end

    def remove_positions
      orderable_keys.each do |field|
        remove_one_position(field)
      end
    end

    def apply_one_position(field, target_position)
      return unless changed?(field)

      set_lock(field) if use_transactions && !embedded?

      f = orderable_field(field)
      scope = orderable_scope(field)
      scope_changed = orderable_scope_changed?(field)

      # Set scope-level lock if scope changed
      if use_transactions && persisted? && !embedded? && scope_changed
        set_lock(field, true)
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
        existing_doc = doc.class.unscoped.find(_id)
        self.class.new(existing_doc).remove_one_position(field)
      end

      # Return if there is no instruction to change the position
      in_list = persisted? && current
      return if in_list && !target_position

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
      doc.set({ f => target }.merge(changed_scope_hash(field))) if use_transactions && persisted? && !embedded?
      doc.send("orderable_#{field}_position=", target)
    end

    def remove_one_position(field)
      f = orderable_field(field)
      current = orderable_position(field)
      set_lock(field) if use_transactions && !embedded?
      orderable_scope(field).gt(f => current).inc(f => -1)
    end

    protected

    delegate :orderable_keys,
             :orderable_field,
             :orderable_position,
             :orderable_scope,
             :orderable_scope_changed?,
             :orderable_top,
             :orderable_bottom,
             :_id,
             :new_record?,
             :persisted?,
             :embedded?,
             :collection_name,
             to: :doc

    def move_all
      doc.send(:move_all)
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

    def changed?(field)
      return true if new_record? || !doc.send(orderable_field(field)) || move_all[field]
      changeable_keys(field).any? {|f| doc.send("#{f}_changed?") }
    end

    def changeable_keys(field)
      [orderable_field(field)] | scope_keys(field)
    end

    def scope_keys(field)
      orderable_scope(field).selector.keys.map do |f|
        doc.fields[f]&.options&.[](:as) || f
      end
    end

    def changed_scope_hash(field)
      scope_keys(field).each_with_object({}) do |f, hash|
        hash[f] = doc.send(f) if doc.send("#{f}_changed?")
      end
    end

    def set_lock(field, scope_changed = false)
      return unless use_transactions && !embedded?
      model_name = doc.class.orderable_configs[field][:lock_collection].to_s.singularize.classify
      model = Mongoid::Orderable::Models.const_get(model_name)
      attrs = lock_scope(field, scope_changed)
      model.where(attrs).find_one_and_update(attrs, { upsert: true })
    end

    def lock_scope(field, scope_changed = false)
      sel = orderable_scope(field).selector
      scope = ([collection_name] + (scope_changed ? sel.keys : sel.to_a.flatten)).map(&:to_s).join('|')
      { scope: scope }
    end

    def use_transactions
      orderable_keys.any? {|k| doc.class.orderable_configs[k][:use_transactions] }
    end

    def transaction_max_retries
      orderable_keys.map {|k| doc.class.orderable_configs[k][:transaction_max_retries] }.compact.max
    end

    def with_transaction(&_block)
      Mongoid::QueryCache.uncached do
        if use_transactions && !embedded? && !Thread.current[ORDERABLE_TRANSACTION_KEY]
          Thread.current[ORDERABLE_TRANSACTION_KEY] = true
          retries = transaction_max_retries
          begin
            doc.class.with_session(causal_consistency: true) do |session|
              doc.class.with(read: { mode: :primary }) do
                session.start_transaction(read: { mode: :primary },
                                          read_concern: { level: 'majority' },
                                          write_concern: { w: 'majority' })
                yield
                session.commit_transaction
              end
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
