module Server
  module Packet
    # Shorthand for defining new packets and adding them to the definitions
    # list.  This method is for adding input parsing definitions.
    #
    # @param [Fixnum] id the packet id
    # @param [Symbol] name the packet name
    def self.I(id, name, &block)
      definitions_in[id] = Definition.new(id, name, &block)
    end

    # Shorthand for defining new output packets.
    #
    # @param [Fixnum] id the packet id
    # @param [Symbol] name the packet name
    def self.O(id, name, &block)
      definitions_out[name] = Definition.new(id, name, &block)
    end

    I(0x00, :keep_alive) do
    end

    I(0x01, :login) do
      int :version
      string16 :username
      long :map_seed
      byte :dimension
    end

    I(0x02, :handshake) do
      string16 :username
    end

    I(0x03, :chat_message) do
      string16 :message
    end

    I(0x10, :holding_change) do
      short :slot_id
    end

    I(0x0A, :player) do
      bool :on_ground?
    end

    I(0x0B, :player_position) do
      double :x
      double :y
      double :stance
      double :z
      bool :on_ground?
    end

    I(0x0C, :player_look) do
      float :yaw
      float :pitch
      bool :on_ground?
    end

    I(0x0D, :player_position_and_look) do
      double :x
      double :y
      double :stance
      double :z
      float :yaw
      float :pitch
      byte :on_ground
    end

    I(0x0E, :player_digging) do
      byte :status
      int :x
      byte :y
      int :z
      byte :face
    end

    I(0x12, :animation) do
      int :entity_id
      byte :animate
    end

    O(0x00, :keep_alive) do
    end

    O(0x01, :login) do
      int :entity_id
      string16 :_unused
      long :map_seed
      byte :dimension
    end

    O(0x02, :handshake) do
      string16 :connection_hash
    end

    O(0x03, :chat_message) do
      string16 :message
    end

    O(0x04, :time_update) do
      long :time
    end

    O(0x0D, :player_position_and_look) do
      double :x
      double :y
      double :stance
      double :z
      float :yaw
      float :pitch
      bool :on_ground?
    end

    O(0x14, :named_entity_spawn) do
      int :eid
      string16 :player_name
      int :x
      int :y
      int :z
      byte :yaw
      byte :pitch
      short :current_item
    end

    O(0x1F, :entity_relative_move) do
      int :eid
      byte :dx
      byte :dy
      byte :dz
    end

    O(0x20, :entity_look) do
      int :eid
      byte :yaw
      byte :pitch
    end

    O(0x32, :pre_chunk) do
      int :x
      int :z
      bool :initialize?
    end

    O(0x33, :map_chunk) do
      int :x
      short :y
      int :z
      byte :size_x
      byte :size_y
      byte :size_z
      int :compressed_size
      buffer :chunk_data
    end
  end
end
