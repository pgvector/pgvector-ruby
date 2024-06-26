require_relative "lib/pgvector/version"

Gem::Specification.new do |spec|
  spec.name          = "pgvector"
  spec.version       = Pgvector::VERSION
  spec.summary       = "pgvector support for Ruby"
  spec.homepage      = "https://github.com/pgvector/pgvector-ruby"
  spec.license       = "MIT"

  spec.author        = "Andrew Kane"
  spec.email         = "andrew@ankane.org"

  spec.files         = Dir["*.{md,txt}", "{lib}/**/*"]
  spec.require_path  = "lib"

  spec.required_ruby_version = ">= 3.1"
end
