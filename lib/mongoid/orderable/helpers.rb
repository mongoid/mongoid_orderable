module Mongoid
  module Orderable
    module Helpers

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
