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
        without_identity_map do
          orderable_scope_changed_query(column)
        end
      end

      def orderable_scope_changed_query(column)
        !orderable_scoped(column).where(_id: _id).exists?
      end

      def bottom_orderable_position(column = nil)
        column ||= default_orderable_column
        col = orderable_column(column)
        max = orderable_scoped(column).ne(col => nil).max(col)
        return orderable_base(column) unless max
        in_list?(column) ? max : max.next
      end

      # Prevents usage of identity map in Mongoid 3
      def without_identity_map(&block)
        if Mongoid.respond_to?(:unit_of_work)
          Mongoid.unit_of_work(&block)
        else
          block.call
        end
      end
    end
  end
end
