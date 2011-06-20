module Server
  module Client
    module PacketHelpers
      def write(packet)
        @connection.send_data packet
      end

      def send_keepalive
        write Packet::create(:keep_alive, {}).data
      end

      def send_handshake
        write Packet::create(:handshake, {
          :connection_hash => '-'
        }).data
      end

      def send_login
        write Packet::create(:login, {
          :entity_id => @player.entity_id,
          :_unused => '',
          :map_seed => 1,
          :dimension => 0
        }).data
      end

      def send_map_pre_chunks
        (-10..10).each do |x|
          (-10..10).each do |z|
            write Packet::create(:pre_chunk, {
              :x => x,
              :z => z,
              :initialize? => true
            }).data
          end
        end
      end

      def send_map_chunks
        map_chunks = Map::Chunk::generate_test_data
        map_chunks.each do |chunk|
          buffer = IO::Buffer.new chunk.to_bytes

          write Packet::create(:map_chunk, {
            :x => chunk.x,
            :y => chunk.y,
            :z => chunk.z,
            :size_x => chunk.size_x,
            :size_y => chunk.size_y,
            :size_z => chunk.size_z,
            :compressed_size => buffer.data.length,
            :chunk_data => buffer
          }).data
        end
      end

      def send_player_position_and_look
        write Packet::create(:player_position_and_look, {
          :x => @player.position.x,
          :y => @player.position.y,
          :z => @player.position.z,
          :stance => 4,
          :yaw => 0,
          :pitch => 0,
          :on_ground? => 0
        }).data
      end

      def send_message(message)
        write Packet::create(:chat_message, {
          :message => message
        }).data
      end

      def send_named_entity_spawn(player)
        write Packet::create(:named_entity_spawn, {
          :eid => player.entity_id,
          :player_name => player.name,
          :x => player.position.abs_x,
          :y => player.position.abs_y,
          :z => player.position.abs_z,
          :yaw => player.yaw,
          :pitch => player.pitch,
          :current_item => 0
        }).data
      end
    end
  end
end
