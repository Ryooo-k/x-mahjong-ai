# frozen_string_literal: true

require 'test/unit'
require_relative '../../src/domain/tile'
require_relative '../../src/util/tile_definitions'

class TileTest < Test::Unit::TestCase
  def setup
    id = 0
    @manzu_1_tile = Tile.new(id)
  end

  def test_tile_initialization
    assert_equal 0, @manzu_1_tile.id
    assert_equal 0, @manzu_1_tile.code
    assert_equal '1萬', @manzu_1_tile.name
    assert_equal 1, @manzu_1_tile.number
    assert_equal 'm', @manzu_1_tile.suit
    assert_equal nil, @manzu_1_tile.holder
  end

  def test_can_not_generate_tile_when_id_does_not_match
    noting_id = 1000
    assert_raise(ArgumentError) { Tile.new(noting_id) }
  end

  def test_reset
    @manzu_1_tile.holder = '１萬の所有者'
    assert_equal '１萬の所有者', @manzu_1_tile.holder

    @manzu_1_tile.reset
    assert_equal nil, @manzu_1_tile.holder
  end
end
