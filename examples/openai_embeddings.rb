require "json"
require "net/http"
require "pg"
require "pgvector"

conn = PG.connect(dbname: "pgvector_example")
conn.exec("CREATE EXTENSION IF NOT EXISTS vector")

registry = PG::BasicTypeRegistry.new.define_default_types
Pgvector::PG.register_vector(registry)
conn.type_map_for_results = PG::BasicTypeMapForResults.new(conn, registry: registry)

conn.exec("DROP TABLE IF EXISTS documents")
conn.exec("CREATE TABLE documents (id bigserial PRIMARY KEY, content text, embedding vector(1536))")

# https://platform.openai.com/docs/guides/embeddings/how-to-get-embeddings
# input can be an array with 2048 elements
def fetch_embeddings(input)
  url = "https://api.openai.com/v1/embeddings"
  headers = {
    "Authorization" => "Bearer #{ENV.fetch("OPENAI_API_KEY")}",
    "Content-Type" => "application/json"
  }
  data = {
    input: input,
    model: "text-embedding-ada-002"
  }

  response = Net::HTTP.post(URI(url), data.to_json, headers)
  JSON.parse(response.body)["data"].map { |v| v["embedding"] }
end

input = [
  "The dog is barking",
  "The cat is purring",
  "The bear is growling"
]
embeddings = fetch_embeddings(input)

input.zip(embeddings) do |content, embedding|
  conn.exec_params("INSERT INTO documents (content, embedding) VALUES ($1, $2)", [content, embedding])
end

document_id = 1
result = conn.exec_params("SELECT content FROM documents WHERE id != $1 ORDER BY embedding <=> (SELECT embedding FROM documents WHERE id = $1) LIMIT 5", [document_id])
result.each do |row|
  puts row["content"]
end
