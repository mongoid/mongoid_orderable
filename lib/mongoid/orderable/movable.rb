module Mongoid
  module Orderable
    module Movable

      def move_to!(column=nil, target_position)
        move_column_to column, target_position
        save
      end
      alias_method :insert_at!, :move_to!

      def move_to(column=nil, target_position)
        move_column_to column, target_position
      end
      alias_method :insert_at, :move_to

      def move_to= column=nil, target_position
        move_column_to column, target_position
      end
      alias_method :insert_at=, :move_to=

      [:top, :bottom].each do |symbol|
        define_method "move_to_#{symbol}" do |column = nil|
          move_to column, symbol
        end

        define_method "move_to_#{symbol}!" do |column = nil|
          move_to! column, symbol
        end
      end

      [:higher, :lower].each do |symbol|
        define_method "move_#{symbol}" do |column = nil|
          move_to column, symbol
        end

        define_method "move_#{symbol}!" do |column = nil|
          move_to! column, symbol
        end
      end

      protected

      def move_all
        @move_all || {}
      end

      def move_column_to(column, position)
        column ||= default_orderable_column
        @move_all = move_all.merge(column => position)
      end

    end
  end
end
