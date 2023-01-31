# frozen_string_literal: true

module Mongoid
module Orderable
module Mixins
  # This is required to trigger callbacks on embedded objects.
  # Otherwise, the #move_to parameter won't work when saving the parent.
  module Cascadeable
    def in_callback_state?(kind)
      super || move_all.present?
    end
  end
end
end
end
