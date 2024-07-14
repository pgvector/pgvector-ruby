require "numo/narray"
require "pg"
require "pgvector"

# generate random data
rows = 1000000
dimensions = 128
embeddings = Numo::SFloat.new(rows, dimensions).rand

# enable extension
conn = PG.connect(dbname: "pgvector_example")
conn.exec("CREATE EXTENSION IF NOT EXISTS vector")

# create table
conn.exec("DROP TABLE IF EXISTS items")
conn.exec("CREATE TABLE items (id bigserial, embedding vector(#{dimensions}))")

# load data
puts "Loading #{embeddings.shape[0]} rows"
coder = PG::BinaryEncoder::CopyRow.new
conn.copy_data("COPY items (embedding) FROM STDIN WITH (FORMAT BINARY)", coder) do
  embeddings.each_over_axis(0).with_index do |embedding, i|
    # show progress
    putc "." if i % 10000 == 0

    conn.put_copy_data([Pgvector::Vector.new(embedding).to_binary])
  end
end

puts "\nSuccess!"

# create any indexes *after* loading initial data (skipping for this example)
# puts "Creating index"
# conn.exec("SET maintenance_work_mem = '8GB'")
# conn.exec("SET max_parallel_maintenance_workers = 7")
# conn.exec("CREATE INDEX ON items USING hnsw (embedding vector_cosine_ops)")

# update planner statistics for good measure
conn.exec("ANALYZE items")
