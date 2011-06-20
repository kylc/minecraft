module Server
  # Provides utility methods for dealing with low-level data streams, as found
  # in the Minecraft protocol.
  module IO
    # Reads and writes to a buffer. All read and write operations are prefixed
    # with +get_+ or +put_+, respectively.
    module Operations
      # @return [String] the operating string of individual bytes
      attr_reader :data

      def get_byte
        get_bytes(1).unpack('c')[0]
      end

      def put_byte(v)
        @data << [v].pack('c')
      end

      def get_bool
        get_byte == 0x01
      end

      def put_bool(v)
        put_byte(v ? 1 : 0)
      end

      def get_short
        get_bytes(2).unpack('s')[0]
      end

      def put_short(v)
        put_byte v >> 8
        put_byte v
      end

      # TODO: is the offset correct here?
      def get_int
        get_bytes(4).unpack('l')[0]
      end

      def put_int(v)
        put_short v >> 16
        put_short v
      end

      def get_float
        get_bytes(4).unpack('g')[0]
      end

      def put_float(v)
        @data << [v].pack('g')
      end

      # TODO: is the offset correct here?
      def get_long
        get_bytes(8).unpack('q')[0]
      end

      def put_long(v)
        put_int v >> 32
        put_int v
      end

      def get_double
        get_bytes(8).unpack('G')[0]
      end

      def put_double(v)
        @data << [v].pack('G')
      end

      def get_string16
        len = get_short * 2 # 2 bytes per character in UTF-16 (similar enough to UCS-2)
        get_bytes(len).force_encoding('UTF-16BE').encode('US-ASCII', { :invalid => :replace, :undef => :replace }) # TODO: wrong encoding type? yes
      end

      def put_string16(s)
        put_short s.length
        buffer = IO::Buffer.new s.encode('UTF-16BE').unpack('c*') # TODO: wrong encoding type?
        put_buffer buffer
      end

      def get_bytes(length)
        @data.slice!(0, length)
      end

      def put_buffer(bs)
        @data << bs.data
      end
    end

    class Buffer
      include Operations

      # @param [String, Buffer, Array] the data source to be read from
      def initialize(data = [])
        data = data.pack('c*') if data.is_a? Array
        data = data.data.pack('c*') if data.is_a? Buffer
        @data = data
      end
    end
  end
end
