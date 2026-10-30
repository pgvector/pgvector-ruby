require_relative "test_helper"

class SparseVectorTest < Minitest::Test
  def test_hash
    vec = Pgvector::SparseVector.new({2 => 2, 4 => 3, 0 => 1, 3 => 0}, 6)
    assert_equal [1, 0, 2, 0, 3, 0], vec.to_a
    assert_equal [0, 2, 4], vec.indices
  end

  def test_hash_negative_index
    error = assert_raises(RuntimeError) do
      Pgvector::SparseVector.new({-1 => 1}, 3)
    end
    assert_equal "sparsevec index out of bounds", error.message
  end

  def test_hash_higher_index
    error = assert_raises(RuntimeError) do
      Pgvector::SparseVector.new({3 => 1}, 3)
    end
    assert_equal "sparsevec index out of bounds", error.message
  end

  def test_hash_negative_dimensions
    error = assert_raises(RuntimeError) do
      Pgvector::SparseVector.new({}, -1)
    end
    assert_equal "sparsevec cannot have negative dimensions", error.message
  end

  def test_hash_no_dimensions
    error = assert_raises(ArgumentError) do
      Pgvector::SparseVector.new({0 => 1, 2 => 2, 4 => 3})
    end
    assert_equal "missing dimensions", error.message
  end

  def test_array
    vec = Pgvector::SparseVector.new([1, 0, 2, 0, 3, 0])
    assert_equal [1, 0, 2, 0, 3, 0], vec.to_a
  end

  def test_array_dimensions
    error = assert_raises(ArgumentError) do
      Pgvector::SparseVector.new([1, 0, 2, 0, 3, 0], 6)
    end
    assert_equal "extra argument", error.message
  end

  def test_from_text
    vec = Pgvector::SparseVector.from_text("{1:1,3:2,5:3}/6")
    assert_equal [1, 0, 2, 0, 3, 0], vec.to_a
  end

  def test_from_text_zero_dimensions
    assert_empty Pgvector::SparseVector.from_text("{}/0").to_a
  end

  def test_from_text_invalid
    error = assert_raises(RuntimeError) do
      Pgvector::SparseVector.from_text("")
    end
    assert_equal "malformed sparsevec literal", error.message
  end

  def test_from_text_negative_index
    error = assert_raises(RuntimeError) do
      Pgvector::SparseVector.from_text("{0:1}/3")
    end
    assert_equal "sparsevec index out of bounds", error.message
  end

  def test_from_text_higher_index
    error = assert_raises(RuntimeError) do
      Pgvector::SparseVector.from_text("{4:1}/3")
    end
    assert_equal "sparsevec index out of bounds", error.message
  end

  def test_from_text_non_number_index
    error = assert_raises(ArgumentError) do
      Pgvector::SparseVector.from_text("{a:1}/1")
    end
    assert_match "invalid value for Integer()", error.message
  end

  def test_from_text_non_number_value
    error = assert_raises(ArgumentError) do
      Pgvector::SparseVector.from_text("{1:a}/1")
    end
    assert_match "invalid value for Float()", error.message
  end

  def test_from_text_negative_dimensions
    error = assert_raises(RuntimeError) do
      Pgvector::SparseVector.from_text("{}/-1")
    end
    assert_equal "sparsevec cannot have negative dimensions", error.message
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

  def test_equality
    a = Pgvector::SparseVector.new([1, 0, 2, 0, 3, 0])
    b = Pgvector::SparseVector.new([1, 0, 2, 0, 3, 0])
    c = Pgvector::SparseVector.new([1, 0, 2, 0, 3, 1])
    assert_equal a, b
    refute_equal a, c
  end
end
