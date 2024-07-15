require "pg"

module Pgvector
  module PG
    def self.register_vector(registry)
      registry.register_type(0, "vector", TextEncoder::Vector, TextDecoder::Vector)
      registry.register_type(1, "vector", BinaryEncoder::Vector, BinaryDecoder::Vector)

      # no binary decoder for halfvec since unpack does not have directive for half-precision
      registry.register_type(0, "halfvec", TextEncoder::Halfvec, TextDecoder::Halfvec)

      registry.register_type(0, "bit", TextEncoder::Bit, TextDecoder::Bit)
      registry.register_type(1, "bit", BinaryEncoder::Bit, BinaryDecoder::Bit)

      registry.register_type(0, "sparsevec", TextEncoder::Sparsevec, TextDecoder::Sparsevec)
      registry.register_type(1, "sparsevec", BinaryEncoder::Sparsevec, BinaryDecoder::Sparsevec)
    end

    module BinaryDecoder
      class Vector < ::PG::SimpleDecoder
        def decode(string, tuple = nil, field = nil)
          ::Pgvector::Vector.from_binary(string).to_a
        end
      end

      class Bit < ::PG::SimpleDecoder
        def decode(string, tuple = nil, field = nil)
          ::Pgvector::Bit.from_binary(string).to_s
        end
      end

      class Sparsevec < ::PG::SimpleDecoder
        def decode(string, tuple = nil, field = nil)
          ::Pgvector::SparseVector.from_binary(string)
        end
      end
    end

    module BinaryEncoder
      # experimental
      def self.type_map
        tm = ::PG::TypeMapByClass.new
        tm[::Pgvector::Vector] = Vector.new
        tm[::Pgvector::Bit] = Bit.new
        tm[::Pgvector::SparseVector] = Sparsevec.new
        tm
      end

      class Vector < ::PG::SimpleEncoder
        def encode(value)
          value.to_binary
        end
      end

      class Bit < ::PG::SimpleEncoder
        def encode(value)
          value.to_binary
        end
      end

      class Sparsevec < ::PG::SimpleEncoder
        def encode(value)
          value.to_binary
        end
      end
    end

    module TextDecoder
      class Vector < ::PG::SimpleDecoder
        def decode(string, tuple = nil, field = nil)
          ::Pgvector::Vector.from_text(string).to_a
        end
      end

      class Halfvec < ::PG::SimpleDecoder
        def decode(string, tuple = nil, field = nil)
          ::Pgvector::HalfVector.from_text(string).to_a
        end
      end

      class Bit < ::PG::SimpleDecoder
        def decode(string, tuple = nil, field = nil)
          ::Pgvector::Bit.from_text(string).to_s
        end
      end

      class Sparsevec < ::PG::SimpleDecoder
        def decode(string, tuple = nil, field = nil)
          ::Pgvector::SparseVector.from_text(string)
        end
      end
    end

    module TextEncoder
      # experimental
      def self.type_map
        tm = ::PG::TypeMapByClass.new
        tm[::Pgvector::Vector] = Vector.new
        tm[::Pgvector::HalfVector] = Halfvec.new
        tm[::Pgvector::Bit] = Bit.new
        tm[::Pgvector::SparseVector] = Sparsevec.new
        tm
      end

      class Vector < ::PG::SimpleEncoder
        def encode(value)
          value.to_s
        end
      end

      class Halfvec < ::PG::SimpleEncoder
        def encode(value)
          value.to_s
        end
      end

      class Bit < ::PG::SimpleEncoder
        def encode(value)
          value.to_s
        end
      end

      class Sparsevec < ::PG::SimpleEncoder
        def encode(value)
          value.to_s
        end
      end
    end
  end
end
