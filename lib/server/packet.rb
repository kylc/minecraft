module Server
  # A module for defining packet definitions. Packet definitions can be used to
  # parse and write packets in a manner that doesn't require the caller to know
  # any specifics about the protocol.
  module Packet
    @definitions_in, @definitions_out = {}, {}

    class << self
      attr_accessor :definitions_in, :definitions_out

      # A helper method for turning binary data into a +Packet+.
      def parse(data)
        buffer = IO::Buffer.new(data)
        id = buffer.get_byte

        # TODO: remove this
        puts "Packet ID: 0x" + id.to_s(16)

        definition = definitions_in[id]
        definition.parse(buffer) if definition
      end

      # A helper method for transforming a +Packet+ into binary data.
      def create(name, properties)
        definition = definitions_out[name]
        definition.create(properties)
      end
    end

    # A +Definition+ provides a map of how data will be formatted before being
    # written to the client, or after being read from the client.
    class Definition
      # @return [Fixnum] the ID
      attr_reader :id

      # @return [String] the name used for abstracting the lookup process
      attr_reader :name

      # @return [Proc] the stored procedure for parsing incoming data
      attr_reader :block

      # Creates a new packet definition with a block to be evaluated at a later
      # time.
      #
      # @param [Fixnum] id the packet's ID
      # @param [Symbol] name the packet's identifying tag
      def initialize(id, name,  &block)
        @id, @name, @block = id, name, block
      end

      # @return [Packet] the packet extracted from the buffer
      def parse(buffer)
        data = buffer.data
        start_len = data.length

        mapping_buf = MappingGetBuffer.new data
        mapping_buf.instance_eval &@block

        end_len = data.length

        Packet.new id, @name, mapping_buf.mapping
      end

      # @return [Buffer] the encoded packet ready to be sent to the client
      def create(properties)
        mapping_buf = MappingPutBuffer.new(properties)

        mapping_buf.put_byte @id
        mapping_buf.instance_eval &@block

        mapping_buf
      end
    end

    class Packet
      # @return [Fixnum] the id, or nil if the packet is headless
      attr_reader :id

      # @return [Symbol] the name used for abstracting the lookup process
      attr_reader :name

      # @return [Hash] the parsed data mapped to field names
      attr_reader :mapping

      def initialize(id, name, mapping)
        @id, @name, @mapping = id, name, mapping
      end
    end

    # A +Buffer+ implementation that modifies reader methods to accept a single
    # parameter, which is mapped into a hash with the value returned by the
    # original method.  The +get_+ prefix is removed for a more convenient
    # syntax.
    #
    # For instance, if +string16 :prop+ is called within the context of a
    # +MappingGetBuffer+, the method call will be redirected to +get_string16+.
    # The result of +get_string16+ will be stored as +mapping[:prop]+.
    #
    # @see MappingPutBuffer
    class MappingGetBuffer < IO::Buffer
      # @return [Hash] the mapped data
      attr_reader :mapping

      # Grab and define the shorthand for each get_ method
      getters = IO::Buffer.instance_methods.select { |m| m.to_s.index('get_') == 0 }
      getters.each do |m|
        define_method(m.to_s[4..-1]) do |name|
          @mapping[name] = send m
        end
      end

      def initialize(data)
        super(data)
        @mapping = {}
      end
    end

    # A +Buffer+ implementation that is very similar to +MappingGetBuffer+, only
    # in the opposite direction.  Calls to +foo+ are redirect to +put_foo+, with
    # a single argument extracted from the provided +properties+ hash.
    #
    # @see MappingGetBuffer
    class MappingPutBuffer < IO::Buffer
      putters = IO::Buffer.instance_methods.select { |m| m.to_s.index('put_') == 0 }
      putters.each do |m|
        define_method(m.to_s[4..-1]) do |name|
          send m, @properties[name]
        end
      end

      def initialize(properties)
        super()
        @properties = properties
      end
    end
  end
end
