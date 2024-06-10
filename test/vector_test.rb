require_relative "test_helper"

class VectorTest < Minitest::Test
  def test_to_s
    vec = Pgvector::Vector.new([1, 2, 3])
    assert_equal "[1.0,2.0,3.0]", vec.to_s
  end

  def test_to_a
    vec = Pgvector::Vector.new([1, 2, 3])
    assert_equal [1, 2, 3], vec.to_a
  end
end
