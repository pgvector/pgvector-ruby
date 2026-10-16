module Pgvector
  class SparseVector
    attr_reader :dimensions, :indices, :values

    NO_DEFAULT = Object.new

    def initialize(value, dimensions = NO_DEFAULT)
      if value.is_a?(Hash)
        if dimensions == NO_DEFAULT
          raise ArgumentError, "missing dimensions"
        end
        from_hash(value, dimensions)
      else
        unless dimensions == NO_DEFAULT
          raise ArgumentError, "extra argument"
        end
        from_array(value)
      end
    end

    def to_s
      "{#{@indices.zip(@values).map { |i, v| "#{i.to_i + 1}:#{v.to_f}" }.join(",")}}/#{@dimensions.to_i}"
    end

    def to_a
      arr = Array.new(dimensions, 0.0)
      @indices.zip(@values) do |i, v|
        arr[i] = v
      end
      arr
    end

    def to_binary
      nnz = @indices.size
      buffer = [dimensions, nnz, 0].pack("l>l>l>")
      @indices.pack("l>#{nnz}", buffer: buffer)
      @values.pack("g#{nnz}", buffer: buffer)
      buffer
    end

    def ==(other)
      eql?(other)
    end

    def eql?(other)
      other.is_a?(self.class) && dimensions == other.dimensions && indices == other.indices && values == other.values
    end

    def hash
      [dimensions, indices, values].hash
    end

    private

    def from_hash(data, dimensions)
      elements =
        data.filter_map do |i, v|
          v = v.to_f
          [i.to_i, v] if v != 0
        end
      elements.sort!
      @dimensions = dimensions.to_i
      @indices = elements.map(&:first)
      @values = elements.map(&:last)
    end

    def from_array(arr)
      arr = arr.to_a
      @dimensions = arr.size
      @indices = []
      @values = []
      arr.each_with_index do |v, i|
        v = v.to_f
        if v != 0
          @indices << i
          @values << v
        end
      end
    end

    class << self
      def from_text(string)
        elements, dimensions = string.split("/", 2)
        indices = []
        values = []
        elements[1..-2].split(",").each do |e|
          index, value = e.split(":", 2)
          indices << index.to_i - 1
          values << value.to_f
        end
        from_parts(dimensions.to_i, indices, values)
      end

      def from_binary(string)
        dim, nnz, unused = string.unpack("l>l>l>")
        raise "invalid length" if string.bytesize != 12 + 8 * nnz
        raise "expected unused to be 0" if unused != 0
        indices = string.unpack("l>#{nnz}", offset: 12)
        values = string.unpack("g#{nnz}", offset: 12 + nnz * 4)
        from_parts(dim, indices, values)
      end

      private

      def from_parts(dimensions, indices, values)
        allocate.tap do |vec|
          vec.instance_variable_set(:@dimensions, dimensions)
          vec.instance_variable_set(:@indices, indices)
          vec.instance_variable_set(:@values, values)
        end
      end
    end
  end
end
