# frozen_string_literal: true

require 'test/unit'
require_relative '../src/environment/tile'

class TileTest < Test::Unit::TestCase
  def test_initialize_tile
    manzu_1_tile = Tile.new(0, 0, false)
    pinzu_5_tile = Tile.new(55, 13, false)
    souzu_9_tile = Tile.new(104, 26, false)
    haku_tile = Tile.new(124, 31, false)

    assert_equal('1萬', manzu_1_tile.name)
    assert_equal('5筒', pinzu_5_tile.name)
    assert_equal('9索', souzu_9_tile.name)
    assert_equal('白', haku_tile.name)
  end

  def test_validate_tile_id
    manzu_1_id = 0
    manzu_9_code= 8
    assert_raise(ArgumentError) { Tile.new(manzu_1_id, manzu_9_code, false) }
  end

  def test_red_dora
    souzu_5_tile = Tile.new(88, 22, false)
    souzu_5_red_tile = Tile.new(91, 22, true)

    assert_equal(souzu_5_tile.name, souzu_5_red_tile.name)
    assert_equal(true, souzu_5_red_tile.red_dora?)
    assert_equal(false, souzu_5_tile.red_dora?)
  end
end
