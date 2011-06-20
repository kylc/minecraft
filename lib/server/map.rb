module Server
  module Map
    # Represents a single chunk of the Minecraft map.  Note that +x+ points
    # south, +z+ points west, and +y+ points upwards.
    class Chunk
      # @return the start position of the region, in world block coordinates
      #
      # @example Find which chunk is affected
      #   ChunkX = X >> 4
      #   ChunkY = Y >> 7
      #   ChunkZ = Z >> 4
      attr_reader :x, :y, :z

      # @example which local block in the chunk to start at
      #   StartX = X & 15
      #   StartY = Y & 127  (not always 0!)
      #   StartZ = Z & 15
      attr_reader :size_x, :size_y, :size_z

      # @return [Array] the blocks located within this chunk in a one-dimensional
      # array
      #
      # @example Access the block at point [x, z, y]
      #    index = y + (z * (Size_Y+1)) + (x * (Size_Y+1) * (Size_Z+1))
      attr_reader :blocks

      # TODO: take coordinates and size into account
      def initialize(x, y, z, size_x, size_y, size_z, blocks)
        @x, @y, @z = x, y, z
        @size_x, @size_y, @size_z = size_x, size_y, size_z
        @blocks = blocks
      end

      # TODO: move this out of the Map module
      # @return [String] the zlib deflated byte data, ready to be sent to the client
      def to_bytes
        buffer = IO::Buffer.new

        # The block type array
        @blocks.each do |block|
          buffer.put_byte block.type
        end

        # The block metadata array
        @blocks.each_slice(2) do |blocks|
          buffer.put_byte((blocks[0].metadata << 4) + blocks[1].metadata)
        end

        # The block light array
        @blocks.each_slice(2) do |blocks|
          buffer.put_byte((blocks[0].light << 4) + blocks[1].light)
        end

        # The block sky light array
        @blocks.each_slice(2) do |blocks|
          buffer.put_byte((blocks[0].sky_light << 4) + blocks[1].sky_light)
        end

        Zlib::Deflate.deflate buffer.data
      end

      def self.generate_test_data
        chunks = []
        (-16..16).step(16).each do |x|
          (-16..16).step(16).each do |z|
            chunks << generate_test_data_for(x, z)
          end
        end
        chunks
      end

      # TODO: load map data from a file, or generate a real map
      def self.generate_test_data_for(x, z)
        blocks = []

        size_x = 15
        size_z = 15
        size_y = 127

        (0..size_x).each do |x|
          (0..size_z).each do |z|
            # Set the floor layer to stone
            (0..1).each do |y|
              index = y + (z * (size_y+1)) + (x * (size_y+1) * (size_z+1))
              blocks[index] = Block.new 1, 0, 0, 0
            end
            # Set everything above that to air
            (2..size_y).each do |y|
              index = y + (z * (size_y+1)) + (x * (size_y+1) * (size_z+1))
              blocks[index] = Block.new 0, 0, 0, 0
            end
          end
        end

        chunk = Chunk.new x, 0, z, size_x, size_y, size_z, blocks
      end
    end

    class Block
      # @return [Fixnum] the block type; air or water for instance
      attr_reader :type

      # TODO: what is this?
      attr_reader :metadata

      # TODO: what is this?
      attr_reader :light

      # TODO: what is this?
      attr_reader :sky_light

      def initialize(type, metadata, light, sky_light)
        @type, @metadata, @light, @sky_light = type, metadata, light, sky_light
      end
    end
  end
end
