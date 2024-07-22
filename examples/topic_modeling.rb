require "pg"
require "pgvector"
require "tomoto"

conn = PG.connect(dbname: "pgvector_example")
conn.exec("CREATE EXTENSION IF NOT EXISTS vector")

conn.exec("DROP TABLE IF EXISTS documents")
conn.exec("CREATE TABLE documents (id bigserial PRIMARY KEY, content text, embedding vector(20))")

def generate_embeddings(input)
  model = Tomoto::LDA.new(k: 20)
  stop_words = Set.new(["the", "is"])
  input.each do |text|
    model.add_doc(text.downcase.split.reject { |w| stop_words.include?(w) })
  end
  model.train(100) # iterations
  input.map.with_index do |_, i|
    model.docs[i].topics.values
  end
end

input = [
  "The dog is barking",
  "The cat is purring",
  "The bear is growling"
]
embeddings = generate_embeddings(input)

input.zip(embeddings) do |content, embedding|
  conn.exec_params("INSERT INTO documents (content, embedding) VALUES ($1, $2)", [content, embedding])
end

document_id = 1
result = conn.exec_params("SELECT content FROM documents WHERE id != $1 ORDER BY embedding <=> (SELECT embedding FROM documents WHERE id = $1) LIMIT 5", [document_id])
result.each do |row|
  puts row["content"]
end
