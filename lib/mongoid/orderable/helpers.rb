module Mongoid
  module Orderable
    module Helpers

      def default_orderable_column
        self.orderable_keys.first
      end

      private

        def orderable_scoped(column = nil)
          column ||= default_orderable_column

          if embedded?
            send(MongoidOrderable.metadata(self).inverse).send(MongoidOrderable.metadata(self).name).send("orderable_#{column}_scope", self)
          else
            self.orderable_inherited_class.send("orderable_#{column}_scope", self)
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

        def bottom_orderable_position(column = nil)
          column ||= default_orderable_column
          @bottom_orderable_position = begin
            positions_list = orderable_scoped(column).distinct(column)
            return orderable_base(column) if positions_list.empty?
            max = positions_list.map(&:to_i).max.to_i
            in_list?(column) ? max : max.next
          end
        end
    end
  end
end
