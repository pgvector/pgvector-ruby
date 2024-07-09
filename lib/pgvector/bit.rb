module Pgvector
  class Bit
    def initialize(data)
      @data = data.to_str
    end

    def self.from_text(string)
      Bit.new(string)
    end

    def self.from_binary(string)
      length = string[..3].unpack1("l>")
      Bit.new(string[4..].unpack("B*").join[...length])
    end

    def to_s
      @data
    end
  end
end
