require_relative "test_helper"

DB = Sequel.connect("postgres://localhost/pgvector_ruby_test")

DB.run("CREATE EXTENSION IF NOT EXISTS vector")

DB.drop_table? :sequel_items
DB.create_table :sequel_items do
  primary_key :id
  column :embedding, "vector(3)"
end
DB.add_index :sequel_items, :embedding, type: "hnsw", opclass: "vector_l2_ops"

class Item < Sequel::Model(DB[:sequel_items])
  plugin :pgvector, :embedding
end

class TestSequel < Minitest::Test
  def setup
    items.delete
  end

  def test_dataset
    items.insert(embedding: Pgvector.encode([1, 1, 1]))
    items.multi_insert([{embedding: "[2,2,2]"}, {embedding: "[1,1,2]"}])
    results = items.order(Sequel.lit("embedding <-> ?", Pgvector.encode([1, 1, 1]))).limit(5)
    assert_equal [[1, 1, 1], [1, 1, 2], [2, 2, 2]], results.map { |r| Pgvector.decode(r[:embedding]) }
  end

  def test_model
    Item.create(embedding: [1, 1, 1])
    Item.create(embedding: [2, 2, 2])
    Item.create(embedding: [1, 1, 2])

    results = Item.nearest_neighbors(:embedding, [1, 1, 1], distance: "euclidean").limit(5)
    assert_equal [[1, 1, 1], [1, 1, 2], [2, 2, 2]], results.map(&:embedding)
    assert_equal [0, 1, Math.sqrt(3)], results.map { |r| r[:neighbor_distance] }

    results = Item.first.nearest_neighbors(:embedding, distance: "euclidean").limit(5)
    assert_equal [[1, 1, 2], [2, 2, 2]], results.map(&:embedding)
    assert_equal [1, Math.sqrt(3)], results.map { |r| r[:neighbor_distance] }

    results = Item.first.nearest_neighbors(:embedding, distance: "taxicab").limit(5)
    assert_equal [[1, 1, 2], [2, 2, 2]], results.map(&:embedding)
    assert_equal [1, 3], results.map { |r| r[:neighbor_distance] }

    sampled_item = Item.order(Sequel.function(:random)).first
    results = Item.where(id: sampled_item.id).nearest_neighbors(:embedding, [1, 1, 1], distance: "euclidean").limit(1)
    assert_equal [sampled_item.embedding], results.map(&:embedding)
  end

  def items
    DB[:sequel_items]
  end
end
