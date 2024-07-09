require_relative "../plugins/pgvector"

module Sequel
  Dataset.register_extension(:pgvector, Plugins::Pgvector::DatasetMethods)
end
