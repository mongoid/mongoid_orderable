module Mongoid
  module Orderable
    module Listable
      ##
      # Returns items above the current document.
      # Items with a position lower than this document's position.
      def previous_items(column = nil)
        column ||= default_orderable_column
        orderable_scoped(column).where(orderable_column(column).lt => send(column))
      end
      alias prev_items previous_items

      ##
      # Returns items below the current document.
      # Items with a position greater than this document's position.
      def next_items(column = nil)
        column ||= default_orderable_column
        orderable_scoped(column).where(orderable_column(column).gt => send(column))
      end

      # returns the previous item in the list
      def previous_item(column = nil)
        column ||= default_orderable_column
        orderable_scoped(column).where(orderable_column(column) => send(column) - 1).first
      end
      alias prev_item previous_item

      # returns the next item in the list
      def next_item(column = nil)
        column ||= default_orderable_column
        orderable_scoped(column).where(orderable_column(column) => send(column) + 1).first
      end

      def first?(column = nil)
        in_list?(column) && orderable_position(column) == orderable_base(column)
      end

      def last?(column = nil)
        in_list?(column) && orderable_position(column) == bottom_orderable_position(column)
      end

      def in_list?(column = nil)
        persisted? && !orderable_position(column).nil?
      end
    end
  end
end
