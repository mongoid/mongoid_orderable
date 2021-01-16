# frozen_string_literal: true

module Mongoid
  module Orderable
    LOCK = Mutex.new

    class << self
      def configure
        yield(config) if block_given?
      end

      def config
        @config || LOCK.synchronize { @config = ::Mongoid::Orderable::Configs::GlobalConfig.new }
      end
    end

    extend ActiveSupport::Concern

    included do
      class_attribute :orderable_configs
    end

    class_methods do
      def orderable(options = {})
        Mongoid::Orderable::Installer.new(self, options).setup
      end
    end
  end
end
