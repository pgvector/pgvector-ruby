require_relative "test_helper"

class BitTest < Minitest::Test
  def test_array
    vec = Pgvector::Bit.new([true, false, true])
    assert_equal vec.to_s, "101"
  end

  def test_array_empty
    vec = Pgvector::Bit.new([])
    assert_equal vec.to_s, ""
  end

  def test_array_nil
    error = assert_raises(ArgumentError) do
      Pgvector::Bit.new([true, false, nil])
    end
    assert_equal "expected bool array", error.message
  end

  def test_string
    vec = Pgvector::Bit.new("101")
    assert_equal [true, false, true], vec.to_a
  end

  def test_string_empty
    vec = Pgvector::Bit.new("")
    assert_equal [], vec.to_a
  end

  def test_string_two
    error = assert_raises(ArgumentError) do
      Pgvector::Bit.new("201")
    end
    assert_equal "expected bit string", error.message
  end

  def test_from_binary
    assert_equal Pgvector::Bit.new("101"), Pgvector::Bit.from_binary([3, 5 << 5].pack("l>c"))
    assert_equal Pgvector::Bit.new("011111110"), Pgvector::Bit.from_binary([9, 127, 0].pack("l>cc"))
  end

  def test_from_binary_zero_length
    error = assert_raises(ArgumentError) do
      Pgvector::Bit.from_binary("")
    end
    assert_equal "invalid length", error.message
  end

  def test_from_binary_negative_length
    error = assert_raises(ArgumentError) do
      Pgvector::Bit.from_binary([-1].pack("l>"))
    end
    assert_equal "invalid length", error.message
  end

  def test_equality
    a = Pgvector::Bit.new([true, false, true])
    b = Pgvector::Bit.new([true, false, true])
    c = Pgvector::Bit.new([true, false, false])
    assert_equal a, b
    refute_equal a, c
  end
end
