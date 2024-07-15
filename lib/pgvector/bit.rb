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
      length, data = string.unpack("l>B*")
      Bit.new(data[...length])
    end

    def to_s
      @data
    end

    def to_a
      @data.each_char.map { |v| v != "0" }
    end

    def to_binary
      [@data.length, @data].pack("l>B*")
    end
  end
end
