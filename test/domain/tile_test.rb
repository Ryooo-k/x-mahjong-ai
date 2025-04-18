# frozen_string_literal: true

require 'test/unit'
require_relative '../../src/domain/tile'
require_relative '../../src/util/tile_definition'

class TileTest < Test::Unit::TestCase
  def setup
    id = 0
    @manzu_1_tile = Tile.new(id)
  end

  def test_tile_initialization
    assert_equal(0, @manzu_1_tile.id)
    assert_equal(0, @manzu_1_tile.code)
    assert_equal('1萬', @manzu_1_tile.name)
    assert_equal(nil, @manzu_1_tile.holder)
  end

  def test_can_not_generate_tile_when_id_does_not_match
    noting_id = 1000
    assert_raise(ArgumentError) { Tile.new(noting_id) }
  end
end
