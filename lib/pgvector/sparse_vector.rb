module Pgvector
  class SparseVector
    attr_reader :dimensions

    def initialize(dimensions, indices, values)
      @dimensions = dimensions.to_i
      @indices = indices.map(&:to_i)
      @values = values.map(&:to_f)
    end

    def self.from_hash(data, dimensions)
      elements = data.to_a.sort
      indices = elements.map { |v| v[0].to_i }
      values = elements.map { |v| v[1].to_f }
      new(dimensions, indices, values)
    end

    def self.from_dense(arr)
      arr = arr.to_a
      dimensions = arr.size
      indices = []
      values = []
      arr.each_with_index do |v, i|
        if v != 0
          indices << i
          values << v.to_f
        end
      end
      new(dimensions, indices, values)
    end

    def self.from_string(string)
      elements, dimensions = string.split("/", 2)
      indices = []
      values = []
      elements[1..-2].split(",").each do |e|
        index, value = e.split(":", 2)
        indices << index.to_i - 1
        values << value.to_f
      end
      new(dimensions.to_i, indices, values)
    end

    def self.from_binary(string)
      dim, nnz, unused = string[0, 12].unpack("l>l>l>")
      raise "expected unused to be 0" if unused != 0
      indices = string[12, nnz * 4].unpack("l>#{nnz}")
      values = string[(12 + nnz * 4)..-1].unpack("g#{nnz}")
      new(dim, indices, values)
    end

    def to_h
      @indices.zip(@values).to_h
    end

    def to_s
      "{#{@indices.zip(@values).map { |i, v| "#{i.to_i + 1}:#{v.to_f}" }.join(",")}}/#{@dimensions.to_i}"
    end

    def to_a
      result = [0.0] * @dimensions
      @indices.zip(@values) do |i, v|
        result[i] = v
      end
      result
    end
  end
end
