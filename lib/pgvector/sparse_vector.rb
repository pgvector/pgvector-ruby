module Pgvector
  class SparseVector
    def initialize(dimensions, indices, values)
      @dimensions = dimensions.to_i
      @indices = indices.map(&:to_i)
      @values = values.map(&:to_f)
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
      SparseVector.new(dimensions, indices, values)
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
