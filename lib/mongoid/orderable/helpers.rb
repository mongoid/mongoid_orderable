module Mongoid
  module Orderable
    module Helpers
      def orderable_keys
        Array orderable_inherited_class.orderable_configurations.try(:keys)
      end

      def default_orderable_column
        self.class.orderable_configurations.detect { |_c, conf| conf[:default] }.try(:first) || orderable_keys.first
      end

      private

      def orderable_scoped(column = nil)
        column ||= default_orderable_column

        if embedded?
          _parent.send(MongoidOrderable.metadata(self).name).send("orderable_#{column}_scope", self)
        else
          orderable_inherited_class.send("orderable_#{column}_scope", self)
        end
      end

      def orderable_scope_changed?(column)
        if Mongoid.respond_to?(:unit_of_work)
          Mongoid.unit_of_work do
            orderable_scope_changed_query(column)
          end
        else
          orderable_scope_changed_query(column)
        end
      end

      def orderable_scope_changed_query(column)
        !orderable_scoped(column).where(_id: _id).exists?
      end

      def bottom_orderable_position(column = nil)
        column ||= default_orderable_column
        @bottom_orderable_position = begin
          positions_list = orderable_scoped(column).distinct(orderable_column(column)).compact
          return orderable_base(column) if positions_list.empty?
          max = positions_list.map(&:to_i).max.to_i
          in_list?(column) ? max : max.next
        end
      end
    end
  end
end
