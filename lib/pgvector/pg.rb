require "pg"

module Pgvector
  module PG
    def self.register_vector(registry)
      registry.register_type(0, "vector", nil, TextDecoder::Vector)
      registry.register_type(1, "vector", nil, BinaryDecoder::Vector)

      # no binary decoder for halfvec since unpack does not have directive for half-precision
      registry.register_type(0, "halfvec", nil, TextDecoder::Halfvec)

      registry.register_type(0, "sparsevec", nil, TextDecoder::Sparsevec)
      registry.register_type(1, "sparsevec", nil, BinaryDecoder::Sparsevec)
    end

    module BinaryDecoder
      class Vector < ::PG::SimpleDecoder
        def decode(string, tuple = nil, field = nil)
          dim, unused = string[0, 4].unpack("nn")
          raise "expected unused to be 0" if unused != 0
          string[4..-1].unpack("g#{dim}")
        end
      end

      class Sparsevec < ::PG::SimpleDecoder
        def decode(string, tuple = nil, field = nil)
          dim, nnz, unused = string[0, 12].unpack("l>l>l>")
          raise "expected unused to be 0" if unused != 0
          indices = string[12, nnz * 4].unpack("l>#{nnz}")
          values = string[(12 + nnz * 4)..-1].unpack("g#{nnz}")
          SparseVector.new(dim, indices, values)
        end
      end
    end

    module TextDecoder
      class Vector < ::PG::SimpleDecoder
        def decode(string, tuple = nil, field = nil)
          Pgvector.decode(string)
        end
      end

      class Halfvec < ::PG::SimpleDecoder
        def decode(string, tuple = nil, field = nil)
          Pgvector.decode(string)
        end
      end

      class Sparsevec < ::PG::SimpleDecoder
        def decode(string, tuple = nil, field = nil)
          elements, dimensions = string.split("/", 2)
          indices = []
          values = []
          elements[1..-2].split(",").each do |e|
            index, value = e.split(":", 2)
            indices << index.to_i - 1
            values << value.to_f
          end
          SparseVector.new(dimensions.to_i, indices, values)
        end
      end
    end
  end
end
