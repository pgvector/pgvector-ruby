module Pgvector
  class Vector
    def initialize(data)
      # keep as NArray when possible for performance
      @data =
        if numo?(data)
          data.cast_to(Numo::SFloat)
        else
          data.to_a.map(&:to_f)
        end
    end

    def self.from_text(string)
      string = string.to_str
      allocate.tap do |vec|
        vec.instance_variable_set(:@data, string[1..-2].split(",").map(&:to_f))
      end
    end

    def self.from_binary(string)
      string = string.to_str
      dim, unused = string.unpack("nn")
      raise "invalid length" if string.bytesize != 4 + 4 * dim
      raise "expected unused to be 0" if unused != 0
      allocate.tap do |vec|
        vec.instance_variable_set(:@data, string.unpack("g#{dim}", offset: 4))
      end
    end

    def to_s
      "[#{@data.to_a.map(&:to_f).join(",")}]"
    end

    def to_a
      @data.to_a
    end

    def to_binary
      if numo?(@data)
        [@data.shape[0], 0].pack("s>s>") + @data.to_network.to_binary.force_encoding(Encoding::BINARY)
      else
        buffer = [@data.size, 0].pack("s>s>")
        @data.pack("g*", buffer: buffer)
        buffer
      end
    end

    def ==(other)
      eql?(other)
    end

    def eql?(other)
      other.is_a?(self.class) && to_a == other.to_a
    end

    def hash
      to_a.hash
    end

    private

    def numo?(data)
      defined?(Numo::NArray) && data.is_a?(Numo::NArray)
    end
  end
end
