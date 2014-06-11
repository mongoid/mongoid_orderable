module Mongoid
  module Orderable
    module Configurable

      private

        def orderable_position
          send orderable_column
        end

        def orderable_position= value
          send "#{orderable_column}=", value
        end

        def orderable_scoped
          if embedded?
            send(MongoidOrderable.metadata(self).inverse).send(MongoidOrderable.metadata(self).name).orderable_scope(self)
          else
            (orderable_inherited_class || self.class).orderable_scope(self)
          end
        end

        def orderable_scope_changed?
          if Mongoid.respond_to?(:unit_of_work)
            Mongoid.unit_of_work do
              orderable_scope_changed_query
            end
          else
            orderable_scope_changed_query
          end
        end

        def orderable_scope_changed_query
          !orderable_scoped.where(:_id => _id).exists?
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

        def bottom_orderable_position
          @bottom_orderable_position = begin
            positions_list = orderable_scoped.distinct(orderable_column)
            return orderable_base if positions_list.empty?
            max = positions_list.map(&:to_i).max.to_i
            in_list? ? max : max.next
          end
        end
    end
  end
end
