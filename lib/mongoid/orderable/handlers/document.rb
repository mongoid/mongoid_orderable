# frozen_string_literal: true

module Mongoid
module Orderable
module Handlers
  class Document < Base

    def before_create
      apply_all_positions
    end

    def after_create; end

    def before_update
      return unless any_field_changed?
      apply_all_positions
    end

    def after_destroy
      remove_all_positions
    end
  end
end
end
end
