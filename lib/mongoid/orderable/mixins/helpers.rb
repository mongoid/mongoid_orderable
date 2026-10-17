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

    def orderable_bottom(field = nil, in_list = true)
      field ||= default_orderable_field
      f = orderable_field(field)
      scope = orderable_scope(field)
      scope = scope.ne(_id: _id) if embedded?
      max = scope.ne(f => nil).max(f)
      if embedded? && in_list && persisted?
        previous_position = send("#{f}_was")
        max = [max, previous_position].compact.max
      end
      return orderable_top(field) unless max
      in_list ? max : max.next
    end
  end
end
end
end
