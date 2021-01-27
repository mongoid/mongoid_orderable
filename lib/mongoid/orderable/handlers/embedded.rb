# frozen_string_literal: true

module Mongoid
module Orderable
module Handlers
  class Embedded
    attr_reader :doc

    def initialize(doc)
      @doc = doc
    end

    def before_create
      orderable_keys.map {|field| apply_one_position(field, move_all[field]) }
    end

    def after_create; end

    # For new records, or if the orderable scope changes,
    # we must yield the save action inside the transaction.
    def before_update
      return unless orderable_keys.any? {|field| changed?(field) }
      orderable_keys.map {|field| apply_one_position(field, move_all[field]) }
    end

    def after_destroy
      return if doc._root.destroyed?
      orderable_keys.each do |field|
        remove_one_position(field)
      end
    end

    protected

    def apply_one_position(field, target_position)
      return unless changed?(field)

      f = orderable_field(field)
      scope = orderable_scope(field)
      scope_changed = orderable_scope_changed?(field)

      # Get the current position as exists in the database
      current = if scope_changed
                  nil
                else
                  orderable_position(field)
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
      doc.send("orderable_#{field}_position=", target)
    end

    def remove_one_position(field)
      f = orderable_field(field)
      current = orderable_position(field)
      orderable_scope(field).gt(f => current).inc(f => -1)
    end

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
  end
end
end
end
