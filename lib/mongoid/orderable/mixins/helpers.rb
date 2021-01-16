# frozen_string_literal: true

module Mongoid
module Orderable
module Mixins
  module Helpers
    def orderable_keys
      Array(orderable_inherited_class.orderable_configs.try(:keys))
    end

    def default_orderable_column
      self.class.orderable_configs.detect { |_c, conf| conf[:default] }.try(:first) || orderable_keys.first
    end

    private

    def orderable_scope(column = nil)
      column ||= default_orderable_column

      if embedded?
        _parent.send(_association.name).send("orderable_#{column}_scope", self)
      else
        orderable_inherited_class.send("orderable_#{column}_scope", self)
      end
    end

    def orderable_scope_changed?(column)
      !orderable_scope(column).where(_id: _id).exists?
    end

    def bottom_orderable_position(column = nil)
      column ||= default_orderable_column
      col = orderable_column(column)
      max = orderable_scope(column).ne(col => nil).max(col)
      return orderable_base(column) unless max
      in_list?(column) ? max : max.next
    end
  end
end
end
end
