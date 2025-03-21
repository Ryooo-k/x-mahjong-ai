# frozen_string_literal: true

require 'test/unit'
require_relative '../src/environment/tile_wall'
require_relative '../src/environment/player'

class TileWallTest < Test::Unit::TestCase
  def setup
    @tile_wall= TileWall.new
  end

  def test_initialize_tiles
    live_tiles_count = 122
    dead_tiles_count = 14
    all_tiles_count = 136
    assert_equal(live_tiles_count, @tile_wall.live_tiles.size)
    assert_equal(dead_tiles_count, @tile_wall.dead_tiles.size)
    assert_equal(all_tiles_count, @tile_wall.live_tiles.size + @tile_wall.dead_tiles.size)

    tile_class = Tile.new(0, 0, false).class
    @tile_wall.live_tiles.each { |tile| assert_instance_of(tile_class, tile) }
    @tile_wall.dead_tiles.each { |tile| assert_instance_of(tile_class, tile) }
  end

  def test_initialize_dora
    dora = @tile_wall.dead_tiles[0]
    ura_dora = @tile_wall.dead_tiles[5]

    assert_equal(dora, @tile_wall.dora.first)
    assert_equal(ura_dora, @tile_wall.ura_dora.first)
  end

  def test_initialize_red_dora
    red_dora_ids = [19, 55, 91]
    red_tile_wall = TileWall.new(red_dora_ids)
    all_tiles = red_tile_wall.live_tiles + red_tile_wall.dead_tiles

    all_tiles.each do |tile|
      if red_dora_ids.include?(tile.id)
        assert_equal(true, tile.red_dora?)
      else
        assert_equal(false, tile.red_dora?)
      end
    end
  end

  def test_reset
    reset_tile_wall = @tile_wall.reset
    assert_instance_of(@tile_wall.class, reset_tile_wall)
  end

  def test_add_dora
    @tile_wall.add_dora
    kong_count = 1
    dora_count = 2

    assert_equal(kong_count, @tile_wall.kong_count)
    assert_equal(dora_count, @tile_wall.dora.size)
    assert_equal(dora_count, @tile_wall.ura_dora.size)
  end

  def test_max_kong_count
    max_kong_count = 4
    max_kong_count.times { assert_nothing_raised { @tile_wall.add_dora } }

    assert_equal(false, @tile_wall.can_kong?)
    assert_raise(StandardError) { @tile_wall.add_dora }
    assert_equal(max_kong_count, @tile_wall.kong_count)
  end
end
