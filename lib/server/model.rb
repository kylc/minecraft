module Server
  # TODO: how to notify network layer of changes, i.e. position?
  # Module used for the representation of in-game objects, items, characters,
  # etc.  These classes should not be too coupled to the network layer.
  module Model
    @last_entity_id = 0

    def self.next_entity_id
      @last_entity_id += 1
    end

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

    class World
      class << self
        # @return [World] the world
        attr_reader :world

        @world = World.new
      end

      # @return [Array] the list of players in this world
      attr_reader :players

      private

      def initialize
        @players = []
      end
    end

    class Entity
      # @return [Fixnum] the entity's unique ID
      attr_reader :entity_id

      # @return [Position] the entity's current position in the world
      attr_accessor :position

      attr_accessor :yaw, :pitch

      def initialize
        @entity_id = Model::next_entity_id
        @yaw, @pitch = 0, 0
      end
    end

    class Player < Entity
      # @return [String] the player's username
      attr_accessor :name
    end
  end
end
