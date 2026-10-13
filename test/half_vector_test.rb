require_relative "test_helper"

class HalfVectorTest < Minitest::Test
  def test_to_s
    vec = Pgvector::HalfVector.new([1, 2, 3])
    assert_equal "[1.0,2.0,3.0]", vec.to_s
  end

  def test_to_a
    vec = Pgvector::HalfVector.new([1, 2, 3])
    assert_equal [1, 2, 3], vec.to_a
  end

  def test_equality
    a = Pgvector::HalfVector.new([1, 2, 3])
    b = Pgvector::HalfVector.new([1, 2, 3])
    c = Pgvector::HalfVector.new([1, 2, 4])
    assert_equal a, b
    refute_equal a, c
  end
end
