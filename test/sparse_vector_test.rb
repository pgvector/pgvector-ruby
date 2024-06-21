require_relative "test_helper"

class SparseVectorTest < Minitest::Test
  def test_from_hash
    vec = Pgvector::SparseVector.from_hash({0 => 1, 2 => 2, 4 => 3}, 6)
    assert_equal [1, 0, 2, 0, 3, 0], vec.to_a
  end

  def test_from_dense
    vec = Pgvector::SparseVector.from_dense([1, 0, 2, 0, 3, 0])
    assert_equal [1, 0, 2, 0, 3, 0], vec.to_a
  end

  def test_from_string
    vec = Pgvector::SparseVector.from_string("{1:1,3:2,5:3}/6")
    assert_equal [1, 0, 2, 0, 3, 0], vec.to_a
  end

  def test_accessors
    vec = Pgvector::SparseVector.from_dense([1, 0, 2, 0, 3, 0])
    assert_equal 6, vec.dimensions
    assert_equal [0, 2, 4], vec.indices
    assert_equal [1, 2, 3], vec.values
  end

  def test_to_s
    vec = Pgvector::SparseVector.from_dense([1, 0, 2, 0, 3, 0])
    assert_equal "{1:1.0,3:2.0,5:3.0}/6", vec.to_s
  end
end
