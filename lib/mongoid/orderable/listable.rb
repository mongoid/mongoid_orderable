module Mongoid
  module Orderable
    module Listable

      ##
      # Returns items above the current document.
      # Items with a position lower than this document's position.
      def previous_items
        orderable_scoped.where(orderable_column.lt => self.position)
      end
      alias_method :prev_items, :previous_items

      ##
      # Returns items below the current document.
      # Items with a position greater than this document's position.
      def next_items
        orderable_scoped.where(orderable_column.gt => self.position)
      end

      # returns the previous item in the list
      def previous_item
        if previous_items.present?
          previous_position = self.position - 1
          orderable_scoped.where(:position => previous_position).first
        else
          nil
        end
      end
      alias_method :prev_item, :previous_item

      # returns the next item in the list
      def next_item
        if next_items.present?
          next_position = self.position + 1
          orderable_scoped.where(:position => next_position).first
        else
          nil
        end
      end

      def first?
        in_list? && orderable_position == orderable_base
      end

      def last?
        in_list? && orderable_position == bottom_orderable_position
      end

      def in_list?
        !orderable_position.nil?
      end

      def add_to_list
        apply_position @move_to
      end

      def remove_from_list
        MongoidOrderable.inc orderable_scoped.where(orderable_column.gt => orderable_position), orderable_column, -1
      end

    end
  end
end
