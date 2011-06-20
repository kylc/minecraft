module Server
  # TODO: how to notify network layer of changes, i.e. position?
  # Module used for the representation of in-game objects, items, characters,
  # etc.  These classes should not be too coupled to the network layer.
  module Model
    class Position
      BLOCK_SIZE = 32

      # @return [Double] the local coordinate.
      attr_reader :x, :y, :z

      # @return [Fixnum] the absolute coordinate.  These are found by
      # multiplying the local coordinate by +BLOCK_SIZE+.
      attr_reader :abs_x, :abs_y, :abs_z

      def initialize(x, y, z)
        @x, @y, @z = x, y, z
        @abs_x, @abs_y, @abs_z = (x * BLOCK_SIZE).to_i, (y * BLOCK_SIZE).to_i,
          (z * BLOCK_SIZE).to_i
      end
    end

    class Entity
      attr_reader :position

      def position=(position)
        # TODO: notify the client that the position has changed
        @position = position
      end
    end

    class Player < Entity
      # @return [String] the player's username
      attr_reader :name
    end
  end
end
