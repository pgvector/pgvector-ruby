# modules
require_relative "pgvector/sparse_vector"
require_relative "pgvector/version"

module Pgvector
  autoload :PG, "pgvector/pg"

  def self.encode(data)
    "[#{data.to_a.map(&:to_f).join(",")}]"
  end

  def self.decode(string)
    if string[0] == "["
      string[1..-2].split(",").map(&:to_f)
    else
      string
    end
  end
end
