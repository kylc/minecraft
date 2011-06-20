module Server
  class Connection < EventMachine::Connection
    def post_init
      @player = Model::Player.new
      @player.position = Model::Position.new 0.5, 4, 0.5

      @client = Client::Client.new(self, @player)
    end

    def receive_data(data)
      packet = Packet::parse(data)
      puts "Packet.inspect:" + packet.inspect

      @client.received(packet)
    end
  end

  class Server
    attr_reader :host, :port

    def initialize(options)
      @host, @port = options[:host], options[:port]
    end

    def start
      EventMachine::run do
        EventMachine::epoll
        EventMachine::start_server(@host, @port, Connection)

        puts "Server listening for connections on #{@host}:#{@port}..."
      end
    end
  end
end
