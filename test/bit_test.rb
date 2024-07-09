require_relative "test_helper"

class BitTest < Minitest::Test
  def test_to_s
    vec = Pgvector::Bit.new([true, false, true])
    assert_equal "101", vec.to_s
  end

  def test_to_a
    vec = Pgvector::Bit.new([true, false, true])
    assert_equal [true, false, true], vec.to_a
  end
end
