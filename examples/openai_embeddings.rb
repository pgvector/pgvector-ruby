require "json"
require "net/http"
require "pgvector"
require "sequel"

DB = Sequel.connect("postgres://localhost/pgvector_example")

DB.run "CREATE EXTENSION IF NOT EXISTS vector"

DB.drop_table? :articles
DB.create_table :articles do
  primary_key :id
  text :content
  column :embedding, "vector(1536)"
end

class Article < Sequel::Model
  plugin :pgvector, :embedding
end

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

articles = []
input.zip(embeddings) do |content, embedding|
  articles << {content: content, embedding: Pgvector.encode(embedding)}
end
Article.multi_insert(articles)

article = Article.first
# use inner product for performance since embeddings are normalized
pp article.nearest_neighbors(:embedding, distance: "inner_product").limit(5).map(&:content)
