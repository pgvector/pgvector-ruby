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
      raise "invalid length" if string.bytesize != 4 + (length + 7) / 8
      Bit.new(data.byteslice(0, length))
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

    def ==(other)
      eql?(other)
    end

    def eql?(other)
      other.is_a?(self.class) && to_s == other.to_s
    end

    def hash
      to_s.hash
    end
  end
end
