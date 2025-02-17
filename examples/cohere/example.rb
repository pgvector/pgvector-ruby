require "json"
require "net/http"
require "pg"

conn = PG.connect(dbname: "pgvector_example")
conn.exec("CREATE EXTENSION IF NOT EXISTS vector")

conn.exec("DROP TABLE IF EXISTS documents")
conn.exec("CREATE TABLE documents (id bigserial PRIMARY KEY, content text, embedding bit(1024))")

# https://docs.cohere.com/reference/embed
def embed(texts, input_type)
  url = "https://api.cohere.com/v1/embed"
  headers = {
    "Authorization" => "Bearer #{ENV.fetch("CO_API_KEY")}",
    "Content-Type" => "application/json"
  }
  data = {
    texts: texts,
    model: "embed-english-v3.0",
    input_type: input_type,
    embedding_types: ["ubinary"]
  }

  response = Net::HTTP.post(URI(url), data.to_json, headers).tap(&:value)
  JSON.parse(response.body)["embeddings"]["ubinary"].map { |e| e.map { |v| v.chr.unpack1("B*") }.join }
end

input = [
  "The dog is barking",
  "The cat is purring",
  "The bear is growling"
]
embeddings = embed(input, "search_document")
input.zip(embeddings) do |content, embedding|
  conn.exec_params("INSERT INTO documents (content, embedding) VALUES ($1, $2)", [content, embedding])
end

query = "forest"
query_embedding = embed([query], "search_query")[0]
result = conn.exec_params("SELECT content FROM documents ORDER BY embedding <~> $1 LIMIT 5", [query_embedding])
result.each do |row|
  puts row["content"]
end
