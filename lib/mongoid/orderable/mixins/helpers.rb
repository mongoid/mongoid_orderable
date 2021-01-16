# frozen_string_literal: true

module Mongoid
module Orderable
module Mixins
  module Helpers
    def orderable_keys
      Array(orderable_inherited_class.orderable_configs.try(:keys))
    end

    def default_orderable_field
      self.class.orderable_configs.detect {|_c, conf| conf[:default] }.try(:first) || orderable_keys.first
    end

    private

    def orderable_scope(field = nil)
      field ||= default_orderable_field

      if embedded?
        _parent.send(_association.name).send("orderable_#{field}_scope", self)
      else
        orderable_inherited_class.send("orderable_#{field}_scope", self)
      end
    end

    def orderable_scope_changed?(field)
      !orderable_scope(field).where(_id: _id).exists?
    end

    def orderable_bottom(field = nil)
      field ||= default_orderable_field
      f = orderable_field(field)
      max = orderable_scope(field).ne(f => nil).max(f)
      return orderable_top(field) unless max
      in_list?(field) ? max : max.next
    end
  end
end
end
end
