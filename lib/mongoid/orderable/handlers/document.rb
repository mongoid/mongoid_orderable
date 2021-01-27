# frozen_string_literal: true

module Mongoid
module Orderable
module Handlers
  class Document < Base

    def before_create
      if use_transactions
        clear_all_positions
      else
        apply_all_positions
      end
    end

    def after_create
      return unless use_transactions
      apply_all_positions
    end

    def before_update
      return unless any_field_changed?
      apply_all_positions
    end

    def after_destroy
      remove_all_positions
    end

    protected

    def clear_all_positions
      orderable_keys.each {|field| doc.send("orderable_#{field}_position=", nil) }
    end
  end
end
end
end
