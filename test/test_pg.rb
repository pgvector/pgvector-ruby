require_relative "test_helper"

class TestPg < Minitest::Test
  def test_text
    factors = [1.5, 2, 3]
    conn.exec_params("INSERT INTO items (factors) VALUES ($1), (NULL)", [factors])

    res = conn.exec("SELECT * FROM items ORDER BY id").to_a
    assert_equal factors, res[0]["factors"]
    assert_nil res[1]["factors"]
  end

  def test_binary
    factors = [1.5, 2, 3]
    conn.exec_params("INSERT INTO items (factors) VALUES ($1), (NULL)", [factors])

    res = conn.exec("SELECT * FROM items ORDER BY id", [], 1).to_a
    assert_equal factors, res[0]["factors"]
    assert_nil res[1]["factors"]
  end

  def conn
    @conn ||= begin
      conn = PG.connect(dbname: "pgvector_ruby_test")

      unless conn.exec("SELECT 1 FROM pg_extension WHERE extname = 'vector'").any?
        conn.exec("CREATE EXTENSION IF NOT EXISTS vector")
      end
      conn.exec("DROP TABLE IF EXISTS items")
      conn.exec("CREATE TABLE items (id bigserial primary key, factors vector(3))")

      registry = PG::BasicTypeRegistry.new.define_default_types
      Pgvector::PG.register_vector(registry)
      conn.type_map_for_queries = PG::BasicTypeMapForQueries.new(conn, registry: registry)
      conn.type_map_for_results = PG::BasicTypeMapForResults.new(conn, registry: registry)
      conn
    end
  end
end
