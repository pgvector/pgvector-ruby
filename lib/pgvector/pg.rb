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
          Pgvector.decode_binary(string)
        end
      end

      class Sparsevec < ::PG::SimpleDecoder
        def decode(string, tuple = nil, field = nil)
          SparseVector.from_binary(string)
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
          SparseVector.from_string(string)
        end
      end
    end
  end
end
