module Pgvector
  class HalfVector
    def initialize(data)
      @data = data.to_a.map(&:to_f)
    end

    def self.from_string(string)
      HalfVector.new(string[1..-2].split(",").map(&:to_f))
    end

    def to_s
      "[#{@data.to_a.map(&:to_f).join(",")}]"
    end

    def to_a
      @data
    end
  end
end
