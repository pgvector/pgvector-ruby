# pgvector-ruby

[pgvector](https://github.com/pgvector/pgvector) support for Ruby

Supports [pg](https://github.com/ged/ruby-pg) and [Sequel](https://github.com/jeremyevans/sequel)

For Rails, check out [Neighbor](https://github.com/ankane/neighbor)

[![Build Status](https://github.com/pgvector/pgvector-ruby/actions/workflows/build.yml/badge.svg)](https://github.com/pgvector/pgvector-ruby/actions)

## Installation

Add this line to your application’s Gemfile:

```ruby
gem "pgvector"
```

And follow the instructions for your database library:

- [pg](#pg)
- [Sequel](#sequel)

Or check out some examples:

- [Embeddings](examples/openai/example.rb) with OpenAI
- [Binary embeddings](examples/cohere/example.rb) with Cohere
- [Sentence embeddings](examples/informers/example.rb) with Informers
- [Hybrid search](examples/hybrid/example.rb) with Informers (Reciprocal Rank Fusion)
- [Sparse search](examples/sparse/example.rb) with Transformers.rb
- [Morgan fingerprints](examples/rdkit/example.rb) with RDKit.rb
- [Topic modeling](examples/tomoto/example.rb) with tomoto.rb
- [User-based recommendations](examples/disco/user_recs.rb) with Disco
- [Item-based recommendations](examples/disco/item_recs.rb) with Disco
- [Horizontal scaling](examples/citus/example.rb) with Citus
- [Bulk loading](examples/loading/example.rb) with `COPY`

## pg

Enable the extension

```ruby
conn.exec("CREATE EXTENSION IF NOT EXISTS vector")
```

Optionally enable type casting for results

```ruby
registry = PG::BasicTypeRegistry.new.define_default_types
Pgvector::PG.register_vector(registry)
conn.type_map_for_results = PG::BasicTypeMapForResults.new(conn, registry: registry)
```

Create a table

```ruby
conn.exec("CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3))")
```

Insert a vector

```ruby
embedding = [1, 2, 3]
conn.exec_params("INSERT INTO items (embedding) VALUES ($1)", [embedding])
```

Get the nearest neighbors to a vector

```ruby
conn.exec_params("SELECT * FROM items ORDER BY embedding <-> $1 LIMIT 5", [embedding]).to_a
```

Add an approximate index

```ruby
conn.exec("CREATE INDEX ON items USING hnsw (embedding vector_l2_ops)")
# or
conn.exec("CREATE INDEX ON items USING ivfflat (embedding vector_l2_ops) WITH (lists = 100)")
```

Use `vector_ip_ops` for inner product and `vector_cosine_ops` for cosine distance

## Sequel

Enable the extension

```ruby
DB.run("CREATE EXTENSION IF NOT EXISTS vector")
```

Create a table

```ruby
DB.create_table :items do
  primary_key :id
  column :embedding, "vector(3)"
end
```

Add the plugin to your model

```ruby
class Item < Sequel::Model
  plugin :pgvector, :embedding
end
```

Insert a vector

```ruby
Item.create(embedding: [1, 1, 1])
```

Get the nearest neighbors to a record

```ruby
item.nearest_neighbors(:embedding, distance: "euclidean").limit(5)
```

Also supports `inner_product`, `cosine`, `taxicab`, `hamming`, and `jaccard` distance

Get the nearest neighbors to a vector

```ruby
Item.nearest_neighbors(:embedding, [1, 1, 1], distance: "euclidean").limit(5)
```

Add an approximate index

```ruby
DB.add_index :items, :embedding, type: "hnsw", opclass: "vector_l2_ops"
```

Use `vector_ip_ops` for inner product and `vector_cosine_ops` for cosine distance

## History

View the [changelog](https://github.com/pgvector/pgvector-ruby/blob/master/CHANGELOG.md)

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/pgvector/pgvector-ruby/issues)
- Fix bugs and [submit pull requests](https://github.com/pgvector/pgvector-ruby/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

To get started with development:

```sh
git clone https://github.com/pgvector/pgvector-ruby.git
cd pgvector-ruby
createdb pgvector_ruby_test
bundle install
bundle exec rake test
```

To run an example:

```sh
cd examples/loading
bundle install
createdb pgvector_example
bundle exec ruby example.rb
```
