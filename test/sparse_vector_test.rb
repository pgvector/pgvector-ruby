require_relative "test_helper"

class SparseVectorTest < Minitest::Test
  def test_hash
    vec = Pgvector::SparseVector.new({2 => 2, 4 => 3, 0 => 1, 3 => 0}, 6)
    assert_equal [1, 0, 2, 0, 3, 0], vec.to_a
    assert_equal [0, 2, 4], vec.indices
  end

  def test_hash_no_dimensions
    error = assert_raises(ArgumentError) do
      Pgvector::SparseVector.new({0 => 1, 2 => 2, 4 => 3})
    end
    assert_equal "dimensions required", error.message
  end

  def test_array
    vec = Pgvector::SparseVector.new([1, 0, 2, 0, 3, 0])
    assert_equal [1, 0, 2, 0, 3, 0], vec.to_a
  end

  def test_array_dimensions
    error = assert_raises(ArgumentError) do
      Pgvector::SparseVector.new([1, 0, 2, 0, 3, 0], 6)
    end
    assert_equal "dimensions not allowed", error.message
  end

  def test_from_text
    vec = Pgvector::SparseVector.from_text("{1:1,3:2,5:3}/6")
    assert_equal [1, 0, 2, 0, 3, 0], vec.to_a
  end

  def test_accessors
    vec = Pgvector::SparseVector.new([1, 0, 2, 0, 3, 0])
    assert_equal 6, vec.dimensions
    assert_equal [0, 2, 4], vec.indices
    assert_equal [1, 2, 3], vec.values
  end

  def test_to_s
    vec = Pgvector::SparseVector.new([1, 0, 2, 0, 3, 0])
    assert_equal "{1:1.0,3:2.0,5:3.0}/6", vec.to_s
  end
end
