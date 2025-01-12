require "numo/narray"
require "pg"
require "pgvector"

# generate random data
rows = 1000000
dimensions = 128
embeddings = Numo::SFloat.new(rows, dimensions).rand
categories = Numo::Int64.new(rows, dimensions).rand(100)
queries = Numo::SFloat.new(10, dimensions).rand

# enable extensions
conn = PG.connect(dbname: "pgvector_citus")
conn.exec("CREATE EXTENSION IF NOT EXISTS citus")
conn.exec("CREATE EXTENSION IF NOT EXISTS vector")

# GUC variables set on the session do not propagate to Citus workers
# https://github.com/citusdata/citus/issues/462
# you can either:
# 1. set them on the system, user, or database and reconnect
# 2. set them for a transaction with SET LOCAL
conn.exec("ALTER DATABASE pgvector_citus SET maintenance_work_mem = '512MB'")
conn.exec("ALTER DATABASE pgvector_citus SET hnsw.ef_search = 20")
conn.close

# reconnect for updated GUC variables to take effect
conn = PG.connect(dbname: "pgvector_citus")

puts "Creating distributed table"
conn.exec("DROP TABLE IF EXISTS items")
conn.exec("CREATE TABLE items (id bigserial, embedding vector(#{dimensions}), category_id bigint, PRIMARY KEY (id, category_id))")
conn.exec("SET citus.shard_count = 4")
conn.exec("SELECT create_distributed_table('items', 'category_id')")

puts "Loading data in parallel"
coder = PG::BinaryEncoder::CopyRow.new
conn.copy_data("COPY items (embedding, category_id) FROM STDIN WITH (FORMAT BINARY)", coder) do
  embeddings.each_over_axis(0).with_index do |embedding, i|
    conn.put_copy_data([Pgvector::Vector.new(embedding).to_binary, [categories[i]].pack("q>")])
  end
end

puts "Creating index in parallel"
conn.exec("CREATE INDEX ON items USING hnsw (embedding vector_l2_ops)")

puts "Running distributed queries"
queries.each_over_axis(0) do |query|
  items = conn.exec_params("SELECT id FROM items ORDER BY embedding <-> $1 LIMIT 10", [Pgvector::Vector.new(query)])
  p items.map { |v| v["id"].to_i }
end
