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

class EmbeddingModel
  def initialize(model_id)
    @model = Transformers::AutoModelForMaskedLM.from_pretrained(model_id)
    @tokenizer = Transformers::AutoTokenizer.from_pretrained(model_id)
    @special_token_ids = @tokenizer.special_tokens_map.map { |_, token| @tokenizer.vocab[token] }
  end

  def embed(input)
    feature = @tokenizer.(input, padding: true, truncation: true, return_tensors: "pt", return_token_type_ids: false)
    output = @model.(**feature)[0]
    values = Torch.max(output * feature[:attention_mask].unsqueeze(-1), dim: 1)[0]
    values = Torch.log(1 + Torch.relu(values))
    values[0.., @special_token_ids] = 0
    values.to_a
  end
end

model = EmbeddingModel.new("opensearch-project/opensearch-neural-sparse-encoding-v1")

input = [
  "The dog is barking",
  "The cat is purring",
  "The bear is growling"
]
embeddings = model.embed(input)
input.zip(embeddings) do |content, embedding|
  conn.exec_params("INSERT INTO documents (content, embedding) VALUES ($1, $2)", [content, Pgvector::SparseVector.new(embedding)])
end

query = "forest"
query_embedding = model.embed([query])[0]
result = conn.exec_params("SELECT content FROM documents ORDER BY embedding <#> $1 LIMIT 5", [Pgvector::SparseVector.new(query_embedding)])
result.each do |row|
  puts row["content"]
end
