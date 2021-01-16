# frozen_string_literal: true

module Mongoid
module Orderable
module Mixins
  module Movable
    def move_to!(target_position, options = {})
      move_column_to target_position, options
      save
    end
    alias insert_at! move_to!

    def move_to(target_position, options = {})
      move_column_to target_position, options
    end
    alias insert_at move_to

    def move_to=(target_position, options = {})
      move_column_to target_position, options
    end
    alias insert_at= move_to=

    %i[top bottom].each do |symbol|
      class_eval <<~KLASS, __FILE__, __LINE__ + 1
        def move_to_#{symbol}(options = {})
          move_to :#{symbol}, options
        end

        def move_to_#{symbol}!(options = {})
          move_to! :#{symbol}, options
        end
      KLASS
    end

    %i[higher lower].each do |symbol|
      class_eval <<~KLASS, __FILE__, __LINE__ + 1
        def move_#{symbol}(options = {})
          move_to :#{symbol}, options
        end

        def move_#{symbol}!(options = {})
          move_to! :#{symbol}, options
        end
      KLASS
    end

    protected

    def move_all
      @move_all || {}
    end

    def move_column_to(position, options)
      column = options[:column] || default_orderable_column
      @move_all = move_all.merge(column => position)
    end
  end
end
end
end
