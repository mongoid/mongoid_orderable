# frozen_string_literal: true

module Mongoid
module Orderable
module Handlers
  class DocumentEmbedded < Document
    def after_destroy
      return if doc._root.destroyed?
      super
    end
  end
end
end
end
