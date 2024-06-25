module Pgvector
  class SparseVector
    attr_reader :dimensions, :indices, :values

    def initialize(value, dimensions = nil)
      if value.is_a?(Hash)
        from_hash(value, dimensions)
      else
        unless dimensions.nil?
          raise ArgumentError, "dimensions not allowed"
        end
        from_array(value)
      end
    end

    def to_s
      "{#{@indices.zip(@values).map { |i, v| "#{i.to_i + 1}:#{v.to_f}" }.join(",")}}/#{@dimensions.to_i}"
    end

    def to_a
      result = Array.new(dimensions) { 0.0 }
      @indices.zip(@values) do |i, v|
        result[i] = v
      end
      result
    end

    private

    def from_hash(data, dimensions)
      if dimensions.nil?
        raise ArgumentError, "dimensions required"
      end
      elements = data.select { |_, v| v != 0 }.sort
      @dimensions = dimensions
      @indices = elements.map { |v| v[0].to_i }
      @values = elements.map { |v| v[1].to_f }
    end

    def from_array(arr)
      arr = arr.to_a
      @dimensions = arr.size
      @indices = []
      @values = []
      arr.each_with_index do |v, i|
        if v != 0
          @indices << i
          @values << v.to_f
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
        dim, nnz, unused = string[0, 12].unpack("l>l>l>")
        raise "expected unused to be 0" if unused != 0
        indices = string[12, nnz * 4].unpack("l>#{nnz}")
        values = string[(12 + nnz * 4)..-1].unpack("g#{nnz}")
        from_parts(dim, indices, values)
      end

      private

      def from_parts(dimensions, indices, values)
        vec = allocate
        vec.instance_variable_set(:@dimensions, dimensions)
        vec.instance_variable_set(:@indices, indices)
        vec.instance_variable_set(:@values, values)
        vec
      end
    end
  end
end
