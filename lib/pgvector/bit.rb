module Pgvector
  class Bit
    def initialize(data)
      if data.is_a?(Array)
        @data = data.map { |v| v ? "1" : "0" }.join
      else
        @data = data.to_str
      end
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

    def to_a
      @data.each_char.map { |v| v != "0" }
    end
  end
end
