module Mongoid
  module Orderable
    module Callbacks
      extend ActiveSupport::Concern

      included do

        protected

        def add_to_list
          apply_position @move_to
        end

        def remove_from_list
          MongoidOrderable.inc orderable_scoped.where(orderable_column.gt => orderable_position), orderable_column, -1
        end

        def apply_position target_position
          if persisted? && !embedded? && orderable_scope_changed?
            self.class.unscoped.find(_id).remove_from_list
            self.orderable_position = nil
          end

          return if !target_position && in_list?

          target_position = target_position_to_position target_position

          unless in_list?
            MongoidOrderable.inc orderable_scoped.where(orderable_column.gte => target_position), orderable_column, 1
          else
            MongoidOrderable.inc(orderable_scoped.where(orderable_column.gte => target_position, orderable_column.lt => orderable_position), orderable_column, 1) if target_position < orderable_position
            MongoidOrderable.inc(orderable_scoped.where(orderable_column.gt => orderable_position, orderable_column.lte => target_position), orderable_column, -1) if target_position > orderable_position
          end

          self.orderable_position = target_position
        end

        def target_position_to_position target_position
          target_position = :bottom unless target_position

          target_position = case target_position.to_sym
            when :top then orderable_base
            when :bottom then bottom_orderable_position
            when :higher then orderable_position.pred
            when :lower then orderable_position.next
          end unless target_position.is_a? Numeric

          target_position = orderable_base if target_position < orderable_base
          target_position = bottom_orderable_position if target_position > bottom_orderable_position
          target_position
        end

      end

      module ClassMethods
        def add_orderable_callbacks
          before_save :add_to_list
          after_destroy :remove_from_list
        end
      end
    end
  end
end
