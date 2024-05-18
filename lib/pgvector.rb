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
      string[1..-2].split(",").map(&:to_f)
    elsif string[0] == "{"
      SparseVector.from_string(string)
    else
      string
    end
  end
end
