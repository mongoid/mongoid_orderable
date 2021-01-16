# frozen_string_literal: true

module Mongoid
module Orderable
module Mixins
  module Callbacks
    extend ActiveSupport::Concern

    included do
      before_save :add_to_list
      after_destroy :remove_from_list

      protected

      def add_to_list
        orderable_keys.each do |field|
          apply_position(field, move_all[field])
        end
      end

      def remove_from_list
        orderable_keys.each do |field|
          remove_position_from_list(field)
        end
      end

      def remove_position_from_list(field)
        col = orderable_field(field)
        pos = orderable_position(field)
        orderable_scope(field).where(col.gt => pos).inc(col => -1)
      end

      def apply_position(field, target_position)
        if persisted? && !embedded? && orderable_scope_changed?(field)
          self.class.unscoped.find(_id).remove_position_from_list(field)
          set(field => nil)
        end

        return if !target_position && in_list?(field)

        target_position = resolve_target_position(field, target_position)
        scope = orderable_scope(field)
        col = orderable_field(field)
        pos = orderable_position(field)

        if !in_list?(field)
          scope.gte(col => target_position).inc(col => 1)
        elsif target_position < pos
          scope.where(col.gte => target_position, col.lt => pos).inc(col => 1)
        elsif target_position > pos
          scope.where(col.gt => pos, col.lte => target_position).inc(col => -1)
        end

        if persisted?
          set(field => target_position)
        else
          send("orderable_#{field}_position=", target_position)
        end
      end

      def resolve_target_position(field, target_position)
        target_position ||= :bottom

        unless target_position.is_a? Numeric
          target_position = case target_position.to_s
                            when 'top' then orderable_top(field)
                            when 'bottom' then orderable_bottom(field)
                            when 'higher' then orderable_position(field).pred
                            when 'lower' then orderable_position(field).next
                            when /\A\d+\Z/ then target_position.to_i
                            else raise Mongoid::Orderable::Errors::InvalidTargetPosition.new(target_position)
                            end
        end

        target_position = orderable_top(field) if target_position < orderable_top(field)
        target_position = orderable_bottom(field) if target_position > orderable_bottom(field)
        target_position
      end
    end
  end
end
end
end
