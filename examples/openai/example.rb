require "json"
require "net/http"
require "pg"
require "pgvector"

conn = PG.connect(dbname: "pgvector_example")
conn.exec("CREATE EXTENSION IF NOT EXISTS vector")

conn.exec("DROP TABLE IF EXISTS documents")
conn.exec("CREATE TABLE documents (id bigserial PRIMARY KEY, content text, embedding vector(1536))")

# https://platform.openai.com/docs/guides/embeddings/how-to-get-embeddings
# input can be an array with 2048 elements
def embed(input)
  url = "https://api.openai.com/v1/embeddings"
  headers = {
    "Authorization" => "Bearer #{ENV.fetch("OPENAI_API_KEY")}",
    "Content-Type" => "application/json"
  }
  data = {
    input: input,
    model: "text-embedding-3-small"
  }

  response = Net::HTTP.post(URI(url), data.to_json, headers).tap(&:value)
  JSON.parse(response.body)["data"].map { |v| v["embedding"] }
end

input = [
  "The dog is barking",
  "The cat is purring",
  "The bear is growling"
]
embeddings = embed(input)
input.zip(embeddings) do |content, embedding|
  conn.exec_params("INSERT INTO documents (content, embedding) VALUES ($1, $2)", [content, embedding])
end

query = "forest"
query_embedding = embed([query])[0]
result = conn.exec_params("SELECT content FROM documents ORDER BY embedding <=> $1 LIMIT 5", [query_embedding])
result.each do |row|
  puts row["content"]
end
