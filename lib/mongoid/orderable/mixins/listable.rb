# frozen_string_literal: true

module Mongoid
module Orderable
module Mixins
  module Listable
    def in_list?(field = nil)
      persisted? && !orderable_position(field).nil?
    end

    # Returns items above the current document.
    # Items with a position lower than this document's position.
    def previous_items(field = nil)
      field ||= default_orderable_field
      orderable_scope(field).lt(orderable_field(field) => send(field))
    end
    alias prev_items previous_items

    # Returns items below the current document.
    # Items with a position greater than this document's position.
    def next_items(field = nil)
      field ||= default_orderable_field
      orderable_scope(field).gt(orderable_field(field) => send(field))
    end

    # Returns the previous item in the list
    def previous_item(field = nil)
      field ||= default_orderable_field
      orderable_scope(field).where(orderable_field(field) => send(field) - 1).first
    end
    alias prev_item previous_item

    # Returns the next item in the list
    def next_item(field = nil)
      field ||= default_orderable_field
      orderable_scope(field).where(orderable_field(field) => send(field) + 1).first
    end

    def first?(field = nil)
      in_list?(field) && orderable_position(field) == orderable_top(field)
    end

    def last?(field = nil)
      in_list?(field) && orderable_position(field) == orderable_bottom(field)
    end
  end
end
end
end
