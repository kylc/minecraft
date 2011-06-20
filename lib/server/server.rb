module Server
  class Connection < EventMachine::Connection
    def post_init
      @player = Model::Player.new
      @player.position = Model::Position.new 0.5, 4, 0.5

      @client = Client::Client.new(self, @player)
      Server.clients << @client
    end

    def receive_data(data)
      packet = Packet::parse(data)
      puts "Packet.inspect:" + packet.inspect

      @client.received(packet)
    end
  end

  class Server
    class << self
      attr_reader :host, :port

      attr_reader :clients

      def start(options)
        @host, @port = options[:host], options[:port]
        @clients = []

        EventMachine::run do
          EventMachine::epoll
          EventMachine::start_server(@host, @port, Connection)

          puts "Server listening for connections on #{@host}:#{@port}..."
        end
      end
    end

    private

    def initialize
    end
  end
end
