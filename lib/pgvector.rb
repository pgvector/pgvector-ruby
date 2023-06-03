# modules
require_relative "pgvector/version"

module Pgvector
  autoload :PG, "pgvector/pg"

  def self.encode(data)
    "[#{data.map(&:to_f).join(",")}]"
  end

  def self.decode(string)
    string[1..-2].split(",").map(&:to_f)
  end
end
