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

DB.drop_table? :users
DB.create_table :users do
  primary_key :id
  column :factors, "vector(20)"
end

class Movie < Sequel::Model
  plugin :pgvector, :factors
end

class User < Sequel::Model
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

users = []
recommender.user_ids.each do |user_id|
  users << {id: user_id, factors: Pgvector.encode(recommender.user_factors(user_id))}
end
User.multi_insert(users)

user = User[123]
pp Movie.nearest_neighbors(:factors, user.factors, distance: "inner_product").limit(5).map(&:name)

# excludes rated, so will be different for some users
# pp recommender.user_recs(user.id).map { |v| v[:item_id] }
