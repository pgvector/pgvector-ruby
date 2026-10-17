module Pgvector
  class Bit
    def initialize(data)
      if data.is_a?(Array)
        bits = {true => "1", false => 0}
        begin
          @data = data.map { |v| bits.fetch(v) }.join
        rescue KeyError
          raise ArgumentError, "expected bool array"
        end
      else
        @data = data.to_str
        unless @data.match?(/\A[01]*\z/)
          raise ArgumentError, "expected bit string"
        end
      end
    end

    def self.from_text(string)
      Bit.new(string.to_str)
    end

    def self.from_binary(string)
      string = string.to_str
      if string.bytesize < 4
        raise ArgumentError, "invalid length"
      end

      length = string.unpack1("l>")
      if string.bytesize != 4 + (length + 7) / 8
        raise ArgumentError, "invalid length"
      end

      data = string.unpack1("B#{length}", offset: 4)
      allocate.tap do |v|
        v.instance_variable_set(:@data, data)
      end
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
