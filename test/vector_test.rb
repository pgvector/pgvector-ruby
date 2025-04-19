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

  def test_numo
    skip if RUBY_PLATFORM == "java"

    a = Pgvector::Vector.new([1, 2, 3])
    b = Pgvector::Vector.new(Numo::NArray.cast([1, 2, 3]))
    assert_equal a.to_s, b.to_s
    assert_equal a.to_a, b.to_a
    assert_equal a.to_binary, b.to_binary
  end
end
