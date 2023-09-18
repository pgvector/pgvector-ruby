# pgvector-ruby

[pgvector](https://github.com/pgvector/pgvector) support for Ruby

Supports [pg](https://github.com/ged/ruby-pg) and [Sequel](https://github.com/jeremyevans/sequel)

For Rails, check out [Neighbor](https://github.com/ankane/neighbor)

[![Build Status](https://github.com/pgvector/pgvector-ruby/workflows/build/badge.svg?branch=master)](https://github.com/pgvector/pgvector-ruby/actions)

## Installation

Add this line to your application’s Gemfile:

```ruby
gem "pgvector"
```

And follow the instructions for your database library:

- [pg](#pg)
- [Sequel](#sequel)

Or check out some examples:

- [Embeddings](examples/openai_embeddings.rb) with OpenAI
- [User-based recommendations](examples/disco_user_recs.rb) with Disco
- [Item-based recommendations](examples/disco_item_recs.rb) with Disco

## pg

Enable the extension

```ruby
conn.exec("CREATE EXTENSION IF NOT EXISTS vector")
```

Register the vector type with your connection

```ruby
registry = PG::BasicTypeRegistry.new.define_default_types
Pgvector::PG.register_vector(registry)
conn.type_map_for_results = PG::BasicTypeMapForResults.new(conn, registry: registry)
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

Also supports `inner_product` and `cosine` distance

Get the nearest neighbors to a vector

```ruby
Item.nearest_neighbors(:embedding, [1, 1, 1], distance: "euclidean").limit(5)
```

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
