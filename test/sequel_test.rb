require_relative "test_helper"

adapter = RUBY_ENGINE == "jruby" ? "jdbc:postgresql" : "postgres"
DB = Sequel.connect("#{adapter}://localhost/pgvector_ruby_test")

if ENV["VERBOSE"]
  require "logger"

  DB.loggers << Logger.new($stdout, formatter: ->(_, _, _, msg) { "#{msg}\n" })
end

DB.run("CREATE EXTENSION IF NOT EXISTS vector")

DB.drop_table? :sequel_items
DB.create_table :sequel_items do
  primary_key :id
  column :embedding, "vector(3)"
  column :half_embedding, "halfvec(3)"
  column :binary_embedding, "bit(3)"
  column :sparse_embedding, "sparsevec(3)"
end
DB.add_index :sequel_items, :embedding, type: "hnsw", opclass: "vector_l2_ops"

class Item < Sequel::Model(DB[:sequel_items])
  plugin :pgvector, :embedding, :half_embedding, :binary_embedding, :sparse_embedding
end

Item.unrestrict_primary_key

class TestSequel < Minitest::Test
  def setup
    items.delete
  end

  def test_dataset
    items.insert(embedding: Pgvector.encode([1, 1, 1]))
    items.multi_insert([{embedding: "[2,2,2]"}, {embedding: "[1,1,2]"}])
    results = items.order(Sequel.lit("embedding <-> ?", Pgvector.encode([1, 1, 1]))).limit(5)
    assert_equal [[1, 1, 1], [1, 1, 2], [2, 2, 2]], results.map { |r| Pgvector.decode(r[:embedding].to_s) }
  end

  def test_extension
    items.insert(embedding: Pgvector.encode([1, 1, 1]))
    items.multi_insert([{embedding: "[2,2,2]"}, {embedding: "[1,1,2]"}])
    results = items.extension(:pgvector).nearest_neighbors(:embedding, [1, 1, 1], distance: "euclidean").limit(5)
    assert_equal [[1, 1, 1], [1, 1, 2], [2, 2, 2]], results.map { |r| Pgvector.decode(r[:embedding].to_s) }
  end

  def test_model_vector_euclidean
    create_items
    results = Item.nearest_neighbors(:embedding, [1, 1, 1], distance: "euclidean").limit(5)
    assert_equal [1, 3, 2], results.map(&:id)
    assert_equal [0, 1, Math.sqrt(3)], results.map { |r| r[:neighbor_distance] }
    assert_equal [[1, 1, 1], [1, 1, 2], [2, 2, 2]], results.map(&:embedding)
  end

  def test_model_vector_inner_product
    create_items
    results = Item.nearest_neighbors(:embedding, [1, 1, 1], distance: "inner_product").limit(5)
    assert_equal [2, 3, 1], results.map(&:id)
    assert_equal [6, 4, 3], results.map { |r| r[:neighbor_distance] }
  end

  def test_model_vector_cosine
    create_items
    results = Item.nearest_neighbors(:embedding, [1, 1, 1], distance: "cosine").limit(5)
    assert_equal [1, 2, 3], results.map(&:id)
  end

  def test_model_vector_taxicab
    create_items
    results = Item.nearest_neighbors(:embedding, [1, 1, 1], distance: "taxicab").limit(5)
    assert_equal [1, 3, 2], results.map(&:id)
    assert_equal [0, 1, 3], results.map { |r| r[:neighbor_distance] }
  end

  def test_instance_vector_euclidean
    create_items
    results = Item.first.nearest_neighbors(:embedding, distance: "euclidean").limit(5)
    assert_equal [3, 2], results.map(&:id)
    assert_equal [1, Math.sqrt(3)], results.map { |r| r[:neighbor_distance] }
  end

  def test_instance_vector_inner_product
    create_items
    results = Item.first.nearest_neighbors(:embedding, distance: "inner_product").limit(5)
    assert_equal [2, 3], results.map(&:id)
    assert_equal [6, 4], results.map { |r| r[:neighbor_distance] }
  end

  def test_instance_vector_cosine
    create_items
    results = Item.first.nearest_neighbors(:embedding, distance: "cosine").limit(5)
    assert_equal [2, 3], results.map(&:id)
  end

  def test_instance_vector_taxicab
    create_items
    results = Item.first.nearest_neighbors(:embedding, distance: "taxicab").limit(5)
    assert_equal [3, 2], results.map(&:id)
    assert_equal [1, 3], results.map { |r| r[:neighbor_distance] }
  end

  def test_model_halfvec_euclidean
    create_items
    results = Item.nearest_neighbors(:half_embedding, [1, 1, 1], distance: "euclidean").limit(5)
    assert_equal [1, 3, 2], results.map(&:id)
    assert_equal [0, 1, Math.sqrt(3)], results.map { |r| r[:neighbor_distance] }
    assert_equal [[1, 1, 1], [1, 1, 2], [2, 2, 2]], results.map(&:half_embedding)
  end

  def test_instance_halfvec_euclidean
    create_items
    results = Item.first.nearest_neighbors(:half_embedding, distance: "euclidean").limit(5)
    assert_equal [3, 2], results.map(&:id)
    assert_equal [1, Math.sqrt(3)], results.map { |r| r[:neighbor_distance] }
  end

  def test_model_bit_hamming
    create_items
    results = Item.nearest_neighbors(:binary_embedding, "101", distance: "hamming").limit(5)
    assert_equal [2, 3, 1], results.map(&:id)
    assert_equal [0, 1, 2], results.map { |r| r[:neighbor_distance] }
    assert_equal ["101", "111", "000"], results.map(&:binary_embedding)
  end

  def test_model_bit_jaccard
    create_items
    results = Item.nearest_neighbors(:binary_embedding, "101", distance: "jaccard").limit(5)
    assert_equal [2, 3, 1], results.map(&:id)
    assert_equal ["101", "111", "000"], results.map(&:binary_embedding)
  end

  def test_instance_bit_hamming
    create_items
    results = Item.first.nearest_neighbors(:binary_embedding, distance: "hamming").limit(5)
    assert_equal [2, 3], results.map(&:id)
    assert_equal [2, 3], results.map { |r| r[:neighbor_distance] }
  end

  def test_model_sparsevec_euclidean
    create_items
    results = Item.nearest_neighbors(:sparse_embedding, Pgvector::SparseVector.new([1, 1, 1]), distance: "euclidean").limit(5)
    assert_equal [1, 3, 2], results.map(&:id)
    assert_equal [0, 1, Math.sqrt(3)], results.map { |r| r[:neighbor_distance] }
    assert_equal [[1, 1, 1], [1, 1, 2], [2, 2, 2]], results.map(&:sparse_embedding).map(&:to_a)
  end

  def test_instance_sparsevec_euclidean
    create_items
    results = Item.first.nearest_neighbors(:sparse_embedding, distance: "euclidean").limit(5)
    assert_equal [3, 2], results.map(&:id)
    assert_equal [1, Math.sqrt(3)], results.map { |r| r[:neighbor_distance] }
  end

  def test_model_dataset
    create_items
    sampled_item = Item.order(Sequel.function(:random)).first
    results = Item.where(id: sampled_item.id).nearest_neighbors(:embedding, [1, 1, 1], distance: "euclidean").limit(1)
    assert_equal [sampled_item.embedding], results.map(&:embedding)
  end

  def items
    DB[:sequel_items]
  end

  def create_items
    Item.create(id: 1, embedding: [1, 1, 1], half_embedding: [1, 1, 1], binary_embedding: "000", sparse_embedding: Pgvector::SparseVector.new([1, 1, 1]))
    Item.create(id: 2, embedding: [2, 2, 2], half_embedding: [2, 2, 2], binary_embedding: "101", sparse_embedding: Pgvector::SparseVector.new([2, 2, 2]))
    Item.create(id: 3, embedding: [1, 1, 2], half_embedding: [1, 1, 2], binary_embedding: "111", sparse_embedding: Pgvector::SparseVector.new([1, 1, 2]))
  end
end
