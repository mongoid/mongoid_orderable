module Mongoid
  module Orderable
    module Movable

      def move_to! target_position
        @move_to = target_position
        save
      end
      alias_method :insert_at!, :move_to!

      def move_to target_position
        @move_to = target_position
      end
      alias_method :insert_at, :move_to

      def move_to= target_position
        @move_to = target_position
      end
      alias_method :insert_at=, :move_to=

      [:top, :bottom].each do |symbol|
        define_method "move_to_#{symbol}" do
          move_to symbol
        end

        define_method "move_to_#{symbol}!" do
          move_to! symbol
        end
      end

      [:higher, :lower].each do |symbol|
        define_method "move_#{symbol}" do
          move_to symbol
        end

        define_method "move_#{symbol}!" do
          move_to! symbol
        end
      end

    end
  end
end
  