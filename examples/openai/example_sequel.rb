require "json"
require "net/http"
require "pgvector"
require "sequel"

DB = Sequel.connect("postgres://localhost/pgvector_example")

DB.run "CREATE EXTENSION IF NOT EXISTS vector"

DB.drop_table? :documents
DB.create_table :documents do
  primary_key :id
  text :content
  column :embedding, "vector(1536)"
end

class Document < Sequel::Model
  plugin :pgvector, :embedding
end

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

documents = []
input.zip(embeddings) do |content, embedding|
  documents << {content: content, embedding: Pgvector.encode(embedding)}
end
Document.multi_insert(documents)

query = "forest"
query_embedding = embed([query])[0]
pp Document.nearest_neighbors(:embedding, query_embedding, distance: "cosine").limit(5).map(&:content)
