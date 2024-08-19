require "pg"
require "pgvector"
require "transformers-rb"

conn = PG.connect(dbname: "pgvector_example")
conn.exec("CREATE EXTENSION IF NOT EXISTS vector")

conn.exec("DROP TABLE IF EXISTS documents")
conn.exec("CREATE TABLE documents (id bigserial PRIMARY KEY, content text, embedding vector(384))")
conn.exec("CREATE INDEX ON documents USING GIN (to_tsvector('english', content))")

model = Transformers::SentenceTransformer.new("sentence-transformers/multi-qa-MiniLM-L6-cos-v1")

input = [
  "The dog is barking",
  "The cat is purring",
  "The bear is growling"
]
embeddings = model.encode(input)
input.zip(embeddings) do |content, embedding|
  conn.exec_params("INSERT INTO documents (content, embedding) VALUES ($1, $2)", [content, embedding])
end

sql = <<~SQL
WITH semantic_search AS (
    SELECT id, RANK () OVER (ORDER BY embedding <=> $2) AS rank
    FROM documents
    ORDER BY embedding <=> $2
    LIMIT 20
),
keyword_search AS (
    SELECT id, RANK () OVER (ORDER BY ts_rank_cd(to_tsvector('english', content), query) DESC)
    FROM documents, plainto_tsquery('english', $1) query
    WHERE to_tsvector('english', content) @@ query
    ORDER BY ts_rank_cd(to_tsvector('english', content), query) DESC
    LIMIT 20
)
SELECT
    COALESCE(semantic_search.id, keyword_search.id) AS id,
    COALESCE(1.0 / ($3 + semantic_search.rank), 0.0) +
    COALESCE(1.0 / ($3 + keyword_search.rank), 0.0) AS score
FROM semantic_search
FULL OUTER JOIN keyword_search ON semantic_search.id = keyword_search.id
ORDER BY score DESC
LIMIT 5
SQL
query = "growling bear"
query_embedding = model.encode(query)
k = 60
result = conn.exec_params(sql, [query, query_embedding, k])
result.each do |row|
  puts "document: #{row["id"]}, RRF score: #{row["score"]}"
end
