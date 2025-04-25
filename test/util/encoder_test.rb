# frozen_string_literal: true

require 'test/unit'
require_relative '../../src/domain/tile'
require_relative '../../src/util/encoder'

class EncoderTest < Test::Unit::TestCase
  def setup
    @encoder = Util::Encoder
    @manzu_1 = Tile.new(0)
    @manzu_2 = Tile.new(4)
    @manzu_3 = Tile.new(8)
    @manzu_4 = Tile.new(12)
    @manzu_5 = Tile.new(16)
    @manzu_6 = Tile.new(20)
    @tile_count = 34.0
  end

  def test_encode_hands
    hands = []
    encoded_hands = @encoder.encode_hands(hands)
    expected = [0] * 34
    assert_equal(expected, encoded_hands)

    hands = [@manzu_1, @manzu_2, @manzu_2, @manzu_3, @manzu_3, @manzu_3]
    encoded_hands = @encoder.encode_hands(hands)
    expected = [1, 2, 3] + [0] * 31 # tile_id順に、1萬が1枚、2萬が2枚、3萬が3枚、それ以外が0枚であることを確認。
    assert_equal(expected, encoded_hands)
  end

  def test_encode_called_tile_table
    called_tile_table = []
    encoded_called_tile_table = @encoder.encode_called_tile_table(called_tile_table)
    expected = [
      [0] * 34,
      [0] * 34,
      [0] * 34,
      [0] * 34
    ]
    assert_equal(expected, encoded_called_tile_table)

    called_tile_table = [[@manzu_1, @manzu_2, @manzu_3], [@manzu_4, @manzu_5, @manzu_6]]
    encoded_called_tile_table = @encoder.encode_called_tile_table(called_tile_table)
    expected = [
      [1, 1, 1] + [0] * 31,
      [0, 0, 0, 1, 1, 1] + [0] * 28,
      [0] * 34,
      [0] * 34
    ]
    assert_equal(expected, encoded_called_tile_table)
  end

  def test_encode_rivers
    rivers = []
    encoded_rivers = @encoder.encode_rivers(rivers)
    expected = [-1] * 24
    assert_equal(expected, encoded_rivers)

    rivers = [@manzu_6, @manzu_1]
    encoded_rivers = @encoder.encode_rivers(rivers)
    normalized_manzu_6_code = @manzu_6.code / @tile_count
    normalized_manzu_1_code = @manzu_1.code / @tile_count
    expected = [normalized_manzu_6_code, normalized_manzu_1_code] + [-1] * 22
    assert_equal(expected, encoded_rivers)
  end

  def test_encode_dora
    dora_tiles = []
    encoded_dora_tiles = @encoder.encode_dora(dora_tiles)
    expected = [-1] * 5
    assert_equal(expected, encoded_dora_tiles)

    dora_tiles = [@manzu_1, @manzu_2]
    encoded_dora_tiles = @encoder.encode_dora(dora_tiles)
    normalized_manzu_1_code = @manzu_1.code / @tile_count
    normalized_manzu_2_code = @manzu_2.code / @tile_count
    expected = [normalized_manzu_1_code , normalized_manzu_2_code] + [-1] * 3
    assert_equal(expected, encoded_dora_tiles)
  end
end
