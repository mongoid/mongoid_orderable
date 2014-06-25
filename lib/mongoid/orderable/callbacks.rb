module Mongoid
  module Orderable
    module Callbacks
      extend ActiveSupport::Concern

      included do

        protected

        def add_to_list
          self.orderable_keys.each do |column|
            apply_position column, move_all[column]
          end
        end

        def remove_from_list
          self.orderable_keys.each do |column|
            col, pos = orderable_column(column), orderable_position(column)
            MongoidOrderable.inc orderable_scoped(column).where(col.gt => pos), col, -1
          end
        end

        def apply_position column, target_position
          if persisted? && !embedded? && orderable_scope_changed?(column)
            self.class.unscoped.find(_id).remove_from_list
            self.send("orderable_#{column}_position=", nil)
          end

          return if !target_position && in_list?(column)

          target_position = target_position_to_position column, target_position
          scope, col, pos = orderable_scoped(column), orderable_column(column), orderable_position(column)

          unless in_list?(column)
            MongoidOrderable.inc scope.where(col.gte => target_position), col, 1
          else
            MongoidOrderable.inc(scope.where(col.gte => target_position, col.lt => pos), col, 1) if target_position < pos
            MongoidOrderable.inc(scope.where(col.gt => pos, col.lte => target_position), col, -1) if target_position > pos
          end

          self.send("orderable_#{column}_position=", target_position)
        end

        def target_position_to_position column, target_position
          target_position = :bottom unless target_position

          target_position = case target_position.to_s
                            when 'top' then orderable_base(column)
                            when 'bottom' then bottom_orderable_position(column)
                            when 'higher' then orderable_position(column).pred
                            when 'lower' then orderable_position(column).next
                            when /\A\d+\Z/ then target_position.to_i
                            else raise Mongoid::Orderable::Errors::InvalidTargetPosition.new target_position
                            end unless target_position.is_a? Numeric

          target_position = orderable_base(column) if target_position < orderable_base(column)
          target_position = bottom_orderable_position(column) if target_position > bottom_orderable_position(column)
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
