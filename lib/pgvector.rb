# modules
require_relative "pgvector/half_vector"
require_relative "pgvector/sparse_vector"
require_relative "pgvector/vector"
require_relative "pgvector/version"

module Pgvector
  autoload :PG, "pgvector/pg"

  def self.encode(data)
    if data.is_a?(Vector) || data.is_a?(HalfVector) || data.is_a?(SparseVector)
      data.to_s
    else
      Vector.new(data).to_s
    end
  end

  def self.decode(string)
    if string[0] == "["
      Vector.from_text(string).to_a
    elsif string[0] == "{"
      SparseVector.from_text(string)
    else
      string
    end
  end
end
