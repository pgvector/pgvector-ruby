require_relative "test_helper"

class PgvectorTest < Minitest::Test
  def test_encode_array
    assert_equal "[1.0,2.0,3.0]", Pgvector.encode([1, 2, 3])
  end

  def test_encode_vector
    assert_equal "[1.0,2.0,3.0]", Pgvector.encode(Pgvector::Vector.new([1, 2, 3]))
  end

  def test_encode_half_vector
    assert_equal "[1.0,2.0,3.0]", Pgvector.encode(Pgvector::HalfVector.new([1, 2, 3]))
  end

  def test_encode_sparse_vector
    assert_equal "{1:1.0,2:2.0,3:3.0}/3", Pgvector.encode(Pgvector::SparseVector.new([1, 2, 3]))
  end

  def test_decode_vector
    assert_equal [1, 2, 3], Pgvector.decode("[1,2,3]")
  end

  def test_decode_sparse_vector
    assert_equal [1, 2, 3], Pgvector.decode("{1:1.0,2:2.0,3:3.0}/3").to_a
  end
end
