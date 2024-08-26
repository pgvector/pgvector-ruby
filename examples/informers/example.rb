require "informers"
require "pg"
require "pgvector"

conn = PG.connect(dbname: "pgvector_example")
conn.exec("CREATE EXTENSION IF NOT EXISTS vector")

conn.exec("DROP TABLE IF EXISTS documents")
conn.exec("CREATE TABLE documents (id bigserial PRIMARY KEY, content text, embedding vector(384))")

model = Informers::Model.new("sentence-transformers/all-MiniLM-L6-v2")

input = [
  "The dog is barking",
  "The cat is purring",
  "The bear is growling"
]
embeddings = model.embed(input)

input.zip(embeddings) do |content, embedding|
  conn.exec_params("INSERT INTO documents (content, embedding) VALUES ($1, $2)", [content, embedding])
end

document_id = 1
result = conn.exec_params("SELECT content FROM documents WHERE id != $1 ORDER BY embedding <=> (SELECT embedding FROM documents WHERE id = $1) LIMIT 5", [document_id])
result.each do |row|
  puts row["content"]
end
