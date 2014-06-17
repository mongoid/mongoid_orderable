module Mongoid
  module Orderable
    module Listable

      ##
      # Returns items above the current document.
      # Items with a position lower than this document's position.
      def previous_items(column=nil)
        column = column || default_orderable_column
        orderable_scoped(column).where(column.lt => public_send(column)).desc(column)
      end
      alias_method :prev_items, :previous_items

      ##
      # Returns items below the current document.
      # Items with a position greater than this document's position.
      def next_items(column=nil)
        column = column || default_orderable_column
        orderable_scoped(column).where(column.gt => public_send(column)).asc(column)
      end

      # returns the previous item in the list
      def previous_item(column=nil)
        column = column || default_orderable_column
        orderable_scoped(column).where(column => public_send(column) - 1).first
      end
      alias_method :prev_item, :previous_item

      # returns the next item in the list
      def next_item(column=nil)
        column = column || default_orderable_column
        orderable_scoped(column).where(column => public_send(column) + 1).first
      end

      def first?(column=nil)
        in_list?(column) && orderable_position(column) == orderable_base(column)
      end

      def last?(column=nil)
        in_list?(column) && orderable_position(column) == bottom_orderable_position(column)
      end

      def in_list?(column=nil)
        !orderable_position(column).nil?
      end

    end
  end
end
