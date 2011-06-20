module Server
  module Client
    class Client
      include PacketHelpers

      attr_reader :player

      def initialize(connection, player)
        @connection = connection
        @player = player

        EventMachine::add_periodic_timer(1) { send_keepalive }
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
          send_player_position_and_look
          send_message "Hello!"

          # Notify other clients that a new client has joined
          other_clients do |me|
            send_named_entity_spawn(me.player)
          end

          # Notify this client of the other clients
          other_clients do |me|
            me.send_named_entity_spawn(@player)
          end
        when :chat_message
          message = packet.mapping[:message]
          other_clients({ :me => self, :message => message }) do |context|
            fmt = context[:me].player.name + ": " + context[:message]
            send_message fmt
          end
        when :player_position
          update_movement(packet)
        when :player_look
          update_look(packet)
        when :player_position_and_look
          update_movement(packet)
          update_look(packet)
        end
      end

      def other_clients(context = self, &block)
        others = Server.clients.select { |x| x.player.entity_id != @player.entity_id }
        others.each do |other|
          other.instance_exec(context, &block)
        end
      end

      def update_movement(packet)
        new_position = Model::Position.new packet.mapping[:x],
          packet.mapping[:y], packet.mapping[:z]

        dx = new_position.x - @player.position.x
        dy = new_position.y - @player.position.y
        dz = new_position.z - @player.position.z

        @player.position = new_position

        other_clients({ :me => self, :dx => dx, :dy => dy, :dz => dz }) do |context|
          write Packet::create(:entity_relative_move, {
            :eid => context[:me].player.entity_id,
            :dx => dx * 32,
            :dy => dy * 32,
            :dz => dz * 32
          }).data
        end
      end

      def update_look(packet)
        @player.yaw = packet.mapping[:yaw]
        @player.pitch = packet.mapping[:pitch]

        other_clients do |me|
          write Packet::create(:entity_look, {
            :eid => me.player.entity_id,
            :yaw => me.player.yaw,
            :pitch => me.player.pitch
          }).data
        end
      end
    end
  end
end
