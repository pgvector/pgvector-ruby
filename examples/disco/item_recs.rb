require "disco"
require "pgvector"
require "sequel"

DB = Sequel.connect("postgres://localhost/pgvector_example")

DB.run "CREATE EXTENSION IF NOT EXISTS vector"

DB.drop_table? :movies
DB.create_table :movies do
  primary_key :id
  text :name
  column :factors, "vector(20)"
end

class Movie < Sequel::Model
  plugin :pgvector, :factors
end

data = Disco.load_movielens
recommender = Disco::Recommender.new(factors: 20)
recommender.fit(data)

movies = []
recommender.item_ids.each do |item_id|
  movies << {name: item_id, factors: Pgvector.encode(recommender.item_factors(item_id))}
end
Movie.multi_insert(movies)

movie = Movie.first(name: "Star Wars (1977)")
pp movie.nearest_neighbors(:factors, distance: "cosine").limit(5).map(&:name)
