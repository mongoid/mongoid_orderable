# frozen_string_literal: true

module Mongoid
module Orderable
module Handlers
  class Base
    attr_reader :doc

    def initialize(doc)
      @doc = doc
      reset_new_record
    end

    private

    delegate :orderable_keys,
             :orderable_field,
             :orderable_position,
             :orderable_position_was,
             :orderable_if,
             :orderable_unless,
             :orderable_scope,
             :orderable_scope_changed?,
             :orderable_top,
             :orderable_bottom,
             :_id,
             :persisted?,
             :embedded?,
             :collection_name,
             to: :doc

    def new_record?
      use_transactions ? @new_record : doc.new_record?
    end

    def use_transactions
      false
    end

    def any_field_changed?
      orderable_keys.any? {|field| changed?(field) } || move_all.any?
    end

    def set_target_positions
      orderable_keys.each do |field|
        next unless (position = doc.send(field))

        move_all[field] ||= position
      end
    end

    def apply_all_positions
      orderable_keys.each {|field| apply_one_position(field, move_all[field]) }
    end

    def apply_one_position(field, target_position)
      return unless allowed?(field) && changed?(field)

      set_lock(field) if use_transactions

      f = orderable_field(field)
      scope = orderable_scope(field)
      scope_changed = orderable_scope_changed?(field)

      # Set scope-level lock if scope changed
      if use_transactions && persisted? && scope_changed
        set_lock(field, true)
        scope_changed = orderable_scope_changed?(field)
      end

      # Get the current position as exists in the database
      current = if new_record? || scope_changed
                  nil
                elsif persisted? && !embedded?
                  scope.where(_id: _id).pluck(f).first
                elsif persisted? && embedded?
                  orderable_position_was(field)
                else
                  orderable_position(field)
                end

      # If scope changed, remove the position from the old scope
      if persisted? && !embedded? && scope_changed
        existing_doc = doc.class.unscoped.find(_id)
        self.class.new(existing_doc).send(:remove_one_position, field)
      end

      # Return if there is no instruction to change the position
      in_list = persisted? && current
      puts 'uuu'
      puts persisted?.inspect
      puts current.inspect
      puts target_position.inspect
      return if in_list && !target_position

      target = resolve_target_position(field, target_position, in_list)

      # Use $inc operator to shift the position of the other documents
      if !in_list
        puts '111'
        scope.gte(f => target).inc(f => 1)
      elsif target < current
        puts '222'
        scope.where(f => { '$gte' => target, '$lt' => current }).inc(f => 1)
      elsif target > current
        puts '333'
        scope.where(f => { '$gt' => current, '$lte' => target }).inc(f => -1)
      end

      # If persisted, update the field in the database atomically
      doc.set({ f => target }.merge(changed_scope_hash(field))) if use_transactions && persisted?
      doc.send("orderable_#{field}_position=", target)
    end

    def remove_all_positions
      orderable_keys.each do |field|
        remove_one_position(field)
      end
    end

    def remove_one_position(field)
      return unless allowed?(field)
      f = orderable_field(field)
      current = orderable_position(field)
      set_lock(field) if use_transactions
      orderable_scope(field).gt(f => current).inc(f => -1)
    end

    def move_all
      doc.send(:move_all)
    end

    def reset
      reset_new_record
      doc.send(:clear_move_all!)
    end

    # Required for transactions, which perform some actions
    # in the after_create callback.
    def reset_new_record
      @new_record = doc.new_record?
    end

    def resolve_target_position(field, target_position, in_list)
      target_position ||= 'bottom'

      unless target_position.is_a?(Numeric)
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

    def allowed?(field)
      cond_if = orderable_if(field)
      cond_unless = orderable_unless(field)

      (cond_if.nil? || resolve_condition(cond_if)) &&
        (cond_unless.nil? || !resolve_condition(cond_unless))
    end

    def resolve_condition(condition)
      case condition
      when Proc
        condition.arity.zero? ? doc.instance_exec(&condition) : condition.call(doc)
      when Symbol
        doc.send(condition)
      else
        condition || false
      end
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

    def set_lock(field, generic = false)
      return unless use_transactions
      model_name = doc.class.orderable_configs[field][:lock_collection].to_s.singularize.classify
      model = Mongoid::Orderable::Models.const_get(model_name)
      attrs = lock_scope(field, generic)
      model.where(attrs).find_one_and_update(attrs.merge(updated_at: Time.now), { upsert: true })
    end

    def lock_scope(field, generic = false)
      sel = orderable_scope(field).selector
      scope = ([collection_name] + (generic ? [field] : sel.to_a.flatten)).map(&:to_s).join('|')
      { scope: scope }
    end
  end
end
end
end
