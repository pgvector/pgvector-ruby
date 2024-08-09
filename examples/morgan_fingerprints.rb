require "pg"
require "rdkit-rb"

def generate_fingerprint(molecule)
  RDKit::Molecule.from_smiles(molecule).morgan_fingerprint
end

conn = PG.connect(dbname: "pgvector_example")
conn.exec("CREATE EXTENSION IF NOT EXISTS vector")

conn.exec("DROP TABLE IF EXISTS molecules")
conn.exec("CREATE TABLE molecules (id text PRIMARY KEY, fingerprint bit(2048))")

molecules = ["Cc1ccccc1", "Cc1ncccc1", "c1ccccn1"]
molecules.each do |molecule|
  fingerprint = generate_fingerprint(molecule)
  conn.exec_params("INSERT INTO molecules (id, fingerprint) VALUES ($1, $2)", [molecule, fingerprint])
end

query_molecule = "c1ccco1"
query_fingerprint = generate_fingerprint(query_molecule)
result = conn.exec_params("SELECT id, fingerprint <%> $1 AS distance FROM molecules ORDER BY distance LIMIT 5", [query_fingerprint])
result.each do |row|
  p row
end
