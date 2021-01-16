# frozen_string_literal: true

module Mongoid
module Orderable
module Mixins
  module Listable
    def in_list?(column = nil)
      persisted? && !orderable_position(column).nil?
    end

    # Returns items above the current document.
    # Items with a position lower than this document's position.
    def previous_items(column = nil)
      column ||= default_orderable_column
      orderable_scope(column).lt(orderable_column(column) => send(column))
    end
    alias prev_items previous_items

    # Returns items below the current document.
    # Items with a position greater than this document's position.
    def next_items(column = nil)
      column ||= default_orderable_column
      orderable_scope(column).gt(orderable_column(column) => send(column))
    end

    # Returns the previous item in the list
    def previous_item(column = nil)
      column ||= default_orderable_column
      orderable_scope(column).where(orderable_column(column) => send(column) - 1).first
    end
    alias prev_item previous_item

    # Returns the next item in the list
    def next_item(column = nil)
      column ||= default_orderable_column
      orderable_scope(column).where(orderable_column(column) => send(column) + 1).first
    end

    def first?(column = nil)
      in_list?(column) && orderable_position(column) == orderable_top(column)
    end

    def last?(column = nil)
      in_list?(column) && orderable_position(column) == orderable_bottom(column)
    end
  end
end
end
end
