# frozen_string_literal: true

module Mongoid
module Orderable
module Handlers
  class Document < Base
    def before_create
      set_new_record_positions
      apply_all_positions
    end

    def after_create
      clear_move_all!
    end

    def before_update
      return unless any_field_changed?
      apply_all_positions
    end

    def after_update
      clear_move_all!
    end

    def after_destroy
      remove_all_positions
      clear_move_all!
    end
  end
end
end
end
