require_relative "test_helper"

DB = Sequel.connect("postgres://localhost/pgvector_ruby_test")

DB.run "CREATE EXTENSION IF NOT EXISTS vector"

DB.drop_table? :sequel_items
DB.create_table :sequel_items do
  primary_key :id
  column :embedding, "vector(3)"
end

class TestSequel < Minitest::Test
  def setup
    items.delete
  end

  def test_works
    items.insert(embedding: Pgvector.encode([1, 1, 1]))
    items.multi_insert([{embedding: "[2,2,2]"}, {embedding: "[1,1,2]"}])
    results = items.order(Sequel.lit("embedding <-> ?", Pgvector.encode([1, 1, 1]))).limit(5).all
    assert_equal [1, 3, 2], results.map { |r| r[:id] }
    assert_equal ["[1,1,1]", "[1,1,2]", "[2,2,2]"], results.map { |r| r[:embedding] }
  end

  def items
    DB[:sequel_items]
  end
end
