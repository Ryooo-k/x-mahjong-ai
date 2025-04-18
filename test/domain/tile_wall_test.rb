# frozen_string_literal: true

require 'test/unit'
require_relative '../../src/domain/tile_wall'
require_relative '../../src/domain/player'

class TileWallTest < Test::Unit::TestCase
  def setup
    @tile_wall= TileWall.new
  end

  def assert_tile_wall_initialization(tile_wall)
    live_walls_count = 122
    dead_walls_count = 14
    assert_equal(live_walls_count, tile_wall.live_walls.size)
    assert_equal(dead_walls_count, tile_wall.dead_walls.size)

    tile_class = Tile.new(0).class
    tile_wall.live_walls.each { |tile| assert_instance_of(tile_class, tile) }
    tile_wall.dead_walls.each { |tile| assert_instance_of(tile_class, tile) }

    open_dora_indicators = tile_wall.dead_walls[0..4]
    blind_dora_indicators = tile_wall.dead_walls[5..9]
    assert_equal(open_dora_indicators, tile_wall.open_dora_indicators)
    assert_equal(blind_dora_indicators, tile_wall.blind_dora_indicators)

    replacement_tiles = tile_wall.dead_walls[10..13]
    assert_equal(replacement_tiles, tile_wall.replacement_tiles)

    red_dora_ids = [19, 55, 91] # 5萬、5筒、5索のid
    tile_wall_with_red = TileWall.new(red_dora_ids)

    tile_wall_with_red.tiles.each do |tile|
      is_red_dora = red_dora_ids.include?(tile.id)
      assert_equal(is_red_dora, tile.red_dora?)
    end
  end

  def test_tile_wall_initialization
    assert_tile_wall_initialization(@tile_wall)
  end

  def test_restores_tile_wall_to_initial_state_when_reset
    reset_tile_wall = @tile_wall.reset
    assert_instance_of(@tile_wall.class, reset_tile_wall)
    assert_tile_wall_initialization(reset_tile_wall)
  end
end
