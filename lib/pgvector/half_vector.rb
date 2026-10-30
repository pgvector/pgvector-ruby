module Pgvector
  class HalfVector
    def initialize(data)
      @data = data.to_a.map(&:to_f)
    end

    def self.from_text(string)
      string = string.to_str
      if string[0] != "[" || string[-1] != "]"
        raise ArgumentError, "malformed halfvec literal"
      end

      data = string[1..-2].split(",").map { |v| Float(v) }
      allocate.tap do |vec|
        vec.instance_variable_set(:@data, data)
      end
    end

    def to_s
      "[#{@data.to_a.map(&:to_f).join(",")}]"
    end

    def to_a
      @data
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
  end
end
