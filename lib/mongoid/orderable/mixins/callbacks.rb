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
        if persisted? && !embedded? && orderable_scope_changed?(column)
          self.class.unscoped.find(_id).remove_position_from_list(column)
          set(column => nil)
        end

        return if !target_position && in_list?(column)

        target_position = resolve_target_position(column, target_position)
        scope = orderable_scope(column)
        col = orderable_column(column)
        pos = orderable_position(column)

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
    end
  end
end
end
end
