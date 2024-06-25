require_relative "test_helper"

class PgTest < Minitest::Test
  def setup
    conn.exec("DELETE FROM pg_items")
  end

  def test_vector_text
    embedding = [1.5, 2, 3]
    conn.exec_params("INSERT INTO pg_items (embedding) VALUES ($1), (NULL)", [embedding])

    res = conn.exec("SELECT * FROM pg_items ORDER BY id").to_a
    assert_equal embedding, res[0]["embedding"]
    assert_nil res[1]["embedding"]
  end

  def test_vector_binary
    embedding = [1.5, 2, 3]
    conn.exec_params("INSERT INTO pg_items (embedding) VALUES ($1), (NULL)", [embedding])

    res = conn.exec_params("SELECT * FROM pg_items ORDER BY id", [], 1).to_a
    assert_equal embedding, res[0]["embedding"]
    assert_nil res[1]["embedding"]
  end

  def test_halfvec_text
    embedding = [1.5, 2, 3]
    conn.exec_params("INSERT INTO pg_items (half_embedding) VALUES ($1), (NULL)", [embedding])

    res = conn.exec("SELECT * FROM pg_items ORDER BY id").to_a
    assert_equal embedding, res[0]["half_embedding"]
    assert_nil res[1]["half_embedding"]
  end

  def test_sparsevec_text
    embedding = Pgvector::SparseVector.new([1.5, 2, 3])
    conn.exec_params("INSERT INTO pg_items (sparse_embedding) VALUES ($1), (NULL)", [embedding])

    res = conn.exec("SELECT * FROM pg_items ORDER BY id").to_a
    assert_equal [1.5, 2, 3], res[0]["sparse_embedding"].to_a
    assert_nil res[1]["sparse_embedding"]
  end

  def test_sparsevec_binary
    embedding = Pgvector::SparseVector.new([1.5, 2, 3])
    conn.exec_params("INSERT INTO pg_items (sparse_embedding) VALUES ($1), (NULL)", [embedding])

    res = conn.exec_params("SELECT * FROM pg_items ORDER BY id", [], 1).to_a
    assert_equal [1.5, 2, 3], res[0]["sparse_embedding"].to_a
    assert_nil res[1]["sparse_embedding"]
  end

  def conn
    @@conn ||= begin
      conn = PG.connect(dbname: "pgvector_ruby_test")

      unless conn.exec("SELECT 1 FROM pg_extension WHERE extname = 'vector'").any?
        conn.exec("CREATE EXTENSION IF NOT EXISTS vector")
      end
      conn.exec("DROP TABLE IF EXISTS pg_items")
      conn.exec("CREATE TABLE pg_items (id bigserial PRIMARY KEY, embedding vector(3), half_embedding halfvec(3), sparse_embedding sparsevec(3))")

      registry = PG::BasicTypeRegistry.new.define_default_types
      Pgvector::PG.register_vector(registry)
      conn.type_map_for_queries = PG::BasicTypeMapForQueries.new(conn, registry: registry)
      conn.type_map_for_results = PG::BasicTypeMapForResults.new(conn, registry: registry)
      conn
    end
  end
end
