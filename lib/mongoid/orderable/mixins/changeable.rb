# frozen_string_literal: true

module Mongoid
module Orderable
module Mixins
  # This is required for dirty tracking on embedded objects.
  # Otherwise, the #move_to parameter won't work when saving the parent.
  module Changeable
    def changed?
      super || move_all.present?
    end
  end
end
end
end
