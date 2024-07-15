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
      Vector.new(string[1..-2].split(",").map(&:to_f))
    end

    def self.from_binary(string)
      dim, unused = string[0, 4].unpack("nn")
      raise "expected unused to be 0" if unused != 0
      Vector.new(string[4..-1].unpack("g#{dim}"))
    end

    def to_s
      "[#{@data.to_a.map(&:to_f).join(",")}]"
    end

    def to_a
      @data.to_a
    end

    def to_binary
      if numo?(@data)
        [@data.shape[0], 0].pack("s>s>") + @data.to_network.to_binary
      else
        buffer = [@data.size, 0].pack("s>s>")
        @data.pack("g*", buffer: buffer)
        buffer
      end
    end

    private

    def numo?(data)
      defined?(Numo::NArray) && data.is_a?(Numo::NArray)
    end
  end
end
