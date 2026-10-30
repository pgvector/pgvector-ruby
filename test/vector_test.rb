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

  def test_from_text
    assert_equal Pgvector::Vector.new([1.5, 2, 3]), Pgvector::Vector.from_text("[1.5,2,3]")
  end

  def test_from_text_zero_dimensions
    assert_equal Pgvector::Vector.new([]), Pgvector::Vector.from_text("[]")
  end

  def test_from_text_zero_length
    error = assert_raises(ArgumentError) do
      Pgvector::Vector.from_text("")
    end
    assert_equal "malformed vector literal", error.message
  end

  def test_from_text_open_bracket
    error = assert_raises(ArgumentError) do
      Pgvector::Vector.from_text("{1]")
    end
    assert_equal "malformed vector literal", error.message
  end

  def test_from_text_close_bracket
    error = assert_raises(ArgumentError) do
      Pgvector::Vector.from_text("[1}")
    end
    assert_equal "malformed vector literal", error.message
  end

  def test_from_text_non_number
    error = assert_raises(ArgumentError) do
      Pgvector::Vector.from_text("[a]")
    end
    assert_match "invalid value for Float()", error.message
  end

  def test_from_binary
    assert_equal Pgvector::Vector.new([1.5, 2, 3]), Pgvector::Vector.from_binary([3, 0, 1.5, 2, 3].pack("s>s>g*"))
  end

  def test_from_binary_zero_length
    error = assert_raises(ArgumentError) do
      Pgvector::Vector.from_binary("")
    end
    assert_equal "invalid length", error.message
  end

  def test_from_binary_non_zero_unused
    error = assert_raises(ArgumentError) do
      Pgvector::Vector.from_binary([0, 1].pack("s>s>"))
    end
    assert_equal "expected unused to be 0", error.message
  end

  def test_equality
    a = Pgvector::Vector.new([1, 2, 3])
    b = Pgvector::Vector.new([1, 2, 3])
    c = Pgvector::Vector.new([1, 2, 4])
    assert_equal a, b
    refute_equal a, c
  end

  def test_numo
    skip if ["jruby", "truffleruby"].include?(RUBY_ENGINE)

    a = Pgvector::Vector.new([1, 2, 3])
    b = Pgvector::Vector.new(Numo::NArray.cast([1, 2, 3]))
    assert_equal a.to_s, b.to_s
    assert_equal a.to_a, b.to_a
    assert_equal a.to_binary, b.to_binary
  end
end
