module Server
  module Client
    class Client
      attr_reader :player

      def initialize(connection, player)
        @connection = connection
        @player = player

        keepalive = KeepaliveTimer.new(1, true)
        keepalive.parent = self
        keepalive.attach(Coolio::Loop.default)
      end

      def received(packet)
        case packet.name
        when :handshake
          send_handshake
        when :login
          @player.name = packet.mapping[:username]

          send_login
          send_map_pre_chunks
          send_map_chunks
          send_player_pos_and_look
          send_message "Hello!"

          # Add another player for testing
          @player2 = Model::Player.new
          @player2.name = "Bob"
          @player2.position = Model::Position.new 0.6, 4, 0.5

          send_named_entity_spawn(@player2)
        when :player_position
          new_position = Model::Position.new packet.mapping[:x],
            packet.mapping[:y], packet.mapping[:z]
          @player.position = new_position
        when :player_position_and_look
          new_position = Model::Position.new packet.mapping[:x],
            packet.mapping[:y], packet.mapping[:z]
          @player.position = new_position

          # TODO: notify other clients
=begin
          @player2.yaw = packet.mapping[:yaw]
          @player2.pitch = packet.mapping[:pitch]
          puts "PUTTING"
          puts @player2.entity_id
          puts @player2.yaw
          puts @player2.pitch
          write Packet::create(:entity_look, {
            :eid => @player2.entity_id,
            :yaw => @player2.yaw,
            :pitch => @player2.pitch
          }).data
=end
        end
      end

      def write(packet)
        @connection.write packet
      end

      def send_keepalive
        write Packet::create(:keep_alive, {}).data
        puts "SENT KEEPALIVE"
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

      def send_player_pos_and_look
        write Packet::create(:player_pos_and_look, {
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

    # TODO: is there a simpler way to do this?
    class KeepaliveTimer < Coolio::TimerWatcher
      def parent=(parent)
        @parent = parent
      end

      def on_timer
        @parent.send_keepalive
      end
    end
  end
end
