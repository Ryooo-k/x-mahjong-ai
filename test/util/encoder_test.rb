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
    assert_equal expected, encoded_hands

    hands = [@manzu_1, @manzu_2, @manzu_2, @manzu_3, @manzu_3, @manzu_3]
    encoded_hands = @encoder.encode_hands(hands)
    expected = [1, 2, 3] + [0] * 31 # tile_id順に、1萬が1枚、2萬が2枚、3萬が3枚、それ以外が0枚であることを確認。
    assert_equal expected, encoded_hands
  end

  def test_encode_melds_list
    melds_list = []
    encoded_melds_list = @encoder.encode_melds_list(melds_list)
    expected = [-1] * 16
    assert_equal expected, encoded_melds_list

    melds_list = [[@manzu_1, @manzu_2, @manzu_3], [@manzu_4, @manzu_5, @manzu_6]]
    encoded_melds_list = @encoder.encode_melds_list(melds_list)
    normalize_manzu_1_code = @manzu_1.code / @tile_count
    normalize_manzu_2_code = @manzu_2.code / @tile_count
    normalize_manzu_3_code = @manzu_3.code / @tile_count
    normalize_manzu_4_code = @manzu_4.code / @tile_count
    normalize_manzu_5_code = @manzu_5.code / @tile_count
    normalize_manzu_6_code = @manzu_6.code / @tile_count
    expected = [
      normalize_manzu_1_code,
      normalize_manzu_2_code,
      normalize_manzu_3_code,
      -1.0,
      normalize_manzu_4_code,
      normalize_manzu_5_code,
      normalize_manzu_6_code,
      -1.0
      ] + [-1.0] * 8
    assert_equal expected, encoded_melds_list
  end

  def test_encode_rivers
    rivers = []
    encoded_rivers = @encoder.encode_rivers(rivers)
    expected = [-1.0] * 24
    assert_equal expected, encoded_rivers

    rivers = [@manzu_6, @manzu_1]
    encoded_rivers = @encoder.encode_rivers(rivers)
    normalized_manzu_6_code = @manzu_6.code / @tile_count
    normalized_manzu_1_code = @manzu_1.code / @tile_count
    expected = [normalized_manzu_6_code, normalized_manzu_1_code] + [-1.0] * 22
    assert_equal expected, encoded_rivers
  end

  def test_encode_dora
    dora_tiles = []
    encoded_dora_tiles = @encoder.encode_doras(dora_tiles)
    expected = [-1.0] * 5
    assert_equal expected, encoded_dora_tiles

    dora_codes = [@manzu_1.code, @manzu_2.code]
    encoded_dora_codes = @encoder.encode_doras(dora_codes)
    normalized_manzu_1_code = @manzu_1.code / @tile_count
    normalized_manzu_2_code = @manzu_2.code / @tile_count
    expected = [normalized_manzu_1_code , normalized_manzu_2_code] + [-1.0] * 3
    assert_equal expected, encoded_dora_codes
  end
end
