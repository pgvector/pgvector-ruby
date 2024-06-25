module Pgvector
  class Vector
    def initialize(data)
      @data = data.to_a.map(&:to_f)
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
      @data
    end
  end
end
