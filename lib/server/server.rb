module Server
  class Connection < Coolio::TCPSocket
    def on_connect
      keepalive = Coolio::TimerWatcher.new(1, true)
      keepalive.on_timer do
        # TODO: write isn't in the TimerWatcher's context, come up with a better
        # method for handling this
        # write Packet::create(:keep_alive, {}).data
      end
      keepalive.attach(Coolio::Loop.default)
    end

    def on_read(data)
      packet = Packet::parse(data)
      puts "Packet.inspect:" + packet.inspect

      player = Model::Player.new
      player.position = Model::Position.new 0.5, 4, 0.5

      # TODO: move all of this packet handling somewhere else
      case packet.name
      when :handshake
        # Handshake response
        write Packet::create(:handshake, {
          :connection_hash => '-'
        }).data
      when :login
        # Login response
        write Packet::create(:login, {
          :entity_id => 1,
          :_unused => '',
          :map_seed => 1,
          :dimension => 0
        }).data

        # Notify the client that map chunks are on the way
        (-10..10).each do |x|
          (-10..10).each do |z|
            write Packet::create(:pre_chunk, {
              :x => x,
              :z => z,
              :initialize? => true
            }).data
          end
        end

        # Now send the actual map chunks
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

        # Player position and look
        write Packet::create(:player_pos_and_look, {
          :x => player.position.x,
          :y => player.position.y,
          :z => player.position.z,
          :stance => 4,
          :yaw => 0,
          :pitch => 0,
          :on_ground? => 0
        }).data

        # Say hello
        write Packet::create(:chat_message, {
          :message => "Hello!"
        }).data

        # Set time to midnight
        # write Packet::create(:time_update, {
        #   :time => 18000
        # }).data
      end
    end
  end

  class Server
    attr_reader :host, :port

    def initialize(options)
      @host, @port = options[:host], options[:port]
    end

    def start
      server = Coolio::TCPServer.new(@host, @port, Connection)
      server.attach(Coolio::Loop.default)

      puts "Server listening for connections on #{@host}:#{@port}..."
      Coolio::Loop.default.run
    end
  end
end
