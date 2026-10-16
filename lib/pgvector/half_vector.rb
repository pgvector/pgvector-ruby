module Pgvector
  class HalfVector
    def initialize(data)
      @data = data.to_a.map(&:to_f)
    end

    def self.from_text(string)
      string = string.to_str
      new(string[1..-2].split(",").map(&:to_f))
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
