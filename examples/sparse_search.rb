# good resources
# https://opensearch.org/blog/improving-document-retrieval-with-sparse-semantic-encoders/
# https://huggingface.co/opensearch-project/opensearch-neural-sparse-encoding-v1

require "pg"
require "pgvector"
require "transformers-rb"

conn = PG.connect(dbname: "pgvector_example")
conn.exec("CREATE EXTENSION IF NOT EXISTS vector")

conn.exec("DROP TABLE IF EXISTS documents")
conn.exec("CREATE TABLE documents (id bigserial PRIMARY KEY, content text, embedding sparsevec(30522))")

model_id = "opensearch-project/opensearch-neural-sparse-encoding-v1"
model = Transformers::AutoModelForMaskedLM.from_pretrained(model_id)
tokenizer = Transformers::AutoTokenizer.from_pretrained(model_id)
special_token_ids = tokenizer.special_tokens_map.map { |_, token| tokenizer.vocab[token] }

fetch_embeddings = lambda do |input|
  feature = tokenizer.(input, padding: true, truncation: true, return_tensors: "pt", return_token_type_ids: false)
  output = model.(**feature)[0]

  values, _ = Torch.max(output * feature[:attention_mask].unsqueeze(-1), dim: 1)
  values = Torch.log(1 + Torch.relu(values))
  values[0.., special_token_ids] = 0
  values.to_a
end

input = [
  "The dog is barking",
  "The cat is purring",
  "The bear is growling"
]
embeddings = fetch_embeddings.(input)
input.zip(embeddings) do |content, embedding|
  conn.exec_params("INSERT INTO documents (content, embedding) VALUES ($1, $2)", [content, Pgvector::SparseVector.new(embedding)])
end

query = "forest"
query_embedding = fetch_embeddings.([query])[0]
result = conn.exec_params("SELECT content FROM documents ORDER BY embedding <#> $1 LIMIT 5", [Pgvector::SparseVector.new(query_embedding)])
result.each do |row|
  puts row["content"]
end
