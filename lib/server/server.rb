module Server
  class Connection < Coolio::TCPSocket
    def on_connect
      @player = Model::Player.new
      @player.position = Model::Position.new 0.5, 4, 0.5

      @client = Client::Client.new(self, @player)
    end

    def on_read(data)
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
      server = Coolio::TCPServer.new(@host, @port, Connection)
      server.attach(Coolio::Loop.default)

      puts "Server listening for connections on #{@host}:#{@port}..."
      Coolio::Loop.default.run
    end
  end
end
