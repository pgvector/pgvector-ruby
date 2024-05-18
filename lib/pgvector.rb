# modules
require_relative "pgvector/sparse_vector"
require_relative "pgvector/version"

module Pgvector
  autoload :PG, "pgvector/pg"

  def self.encode(data)
    if data.is_a?(SparseVector)
      data.to_s
    else
      "[#{data.to_a.map(&:to_f).join(",")}]"
    end
  end

  def self.decode(string)
    if string[0] == "["
      Vector.from_string(string)
    elsif string[0] == "{"
      SparseVector.from_string(string)
    else
      string
    end
  end

  class Vector
    def self.from_string(string)
      string[1..-2].split(",").map(&:to_f)
    end

    def self.from_binary(string)
      dim, unused = string[0, 4].unpack("nn")
      raise "expected unused to be 0" if unused != 0
      string[4..-1].unpack("g#{dim}")
    end
  end

  class HalfVector
    def self.from_string(string)
      string[1..-2].split(",").map(&:to_f)
    end
  end
end
