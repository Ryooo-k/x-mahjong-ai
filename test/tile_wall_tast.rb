# frozen_string_literal: true

require 'test/unit'
require_relative '../src/environment/tile_wall'
require_relative '../src/environment/player'

class TileWallTest < Test::Unit::TestCase
  DORA_CHECKERS = {
    '1萬' => '2萬',
    '2萬' => '3萬',
    '3萬' => '4萬',
    '4萬' => '5萬',
    '5萬' => '6萬',
    '6萬' => '7萬',
    '7萬' => '8萬',
    '8萬' => '9萬',
    '9萬' => '1萬',
  
    '1筒' => '2筒',
    '2筒' => '3筒',
    '3筒' => '4筒',
    '4筒' => '5筒',
    '5筒' => '6筒',
    '6筒' => '7筒',
    '7筒' => '8筒',
    '8筒' => '9筒',
    '9筒' => '1筒',
  
    '1索' => '2索',
    '2索' => '3索',
    '3索' => '4索',
    '4索' => '5索',
    '5索' => '6索',
    '6索' => '7索',
    '7索' => '8索',
    '8索' => '9索',
    '9索' => '1索',
  
    '東' => '南',
    '南' => '西',
    '西' => '北',
    '北' => '東',
  
    '白' => '發',
    '發' => '中',
    '中' => '白'
  }.freeze

  def setup
    @tile_wall= TileWall.new
  end

  def assert_tile_wall_initialization(tile_wall)
    # initialize_live_walls_and_dead_wall
    live_walls_count = 122
    dead_walls_count = 14
    assert_equal(live_walls_count, tile_wall.live_walls.size)
    assert_equal(dead_walls_count, tile_wall.dead_walls.size)

    tile_class = Tile.new(0).class
    tile_wall.live_walls.each { |tile| assert_instance_of(tile_class, tile) }
    tile_wall.dead_walls.each { |tile| assert_instance_of(tile_class, tile) }

    # initialize_open_dora_indicators_and_blind_dora_indicators
    open_dora_indicators = tile_wall.dead_walls[0..4]
    blind_dora_indicators = tile_wall.dead_walls[5..9]
    assert_equal(open_dora_indicators, tile_wall.open_dora_indicators)
    assert_equal(blind_dora_indicators, tile_wall.blind_dora_indicators)

    # initialize_replacement_tiles
    replacement_tiles = tile_wall.dead_walls[10..13]
    assert_equal(replacement_tiles, tile_wall.replacement_tiles)

    # initialize_open_dora_code
    open_dora_checker = DORA_CHECKERS[tile_wall.open_dora_indicators.first.name]
    open_dora_code = tile_wall.open_dora_codes.first
    open_dora_tiles = tile_wall.tiles.select { |tile| tile.code == open_dora_code }
    open_dora_tiles.each { |tile| assert_equal(open_dora_checker, tile.name) }

    # initialize_blind_dora_code
    blind_dora_checker = DORA_CHECKERS[tile_wall.blind_dora_indicators.first.name]
    blind_dora_code = tile_wall.blind_dora_codes.first
    blind_dora_tiles = tile_wall.tiles.select { |tile| tile.code == blind_dora_code }
    blind_dora_tiles.each { |tile| assert_equal(blind_dora_checker, tile.name) }

    # initialize_red_dora
    red_dora_ids = [19, 55, 91] # 5萬、5筒、5索のid
    red_dora_tile_wall = TileWall.new(red_dora_ids)

    red_dora_tile_wall.tiles.each do |tile|
      is_red_dora = red_dora_ids.include?(tile.id)
      assert_equal(is_red_dora, tile.red_dora?)
    end
  end

  def test_initialize_tile_wall
    assert_tile_wall_initialization(@tile_wall)
  end

  def test_restores_tile_wall_to_initial_state_when_reset
    reset_tile_wall = @tile_wall.reset
    assert_instance_of(@tile_wall.class, reset_tile_wall)
    assert_tile_wall_initialization(reset_tile_wall)
  end

  def test_increase_kong_count_when_new_dora_tile_added
    first_kong_count = 0
    second_kong_count = 1
    third_kong_count = 2
    assert_equal(first_kong_count, @tile_wall.kong_count)
    
    @tile_wall.add_dora
    assert_equal(second_kong_count, @tile_wall.kong_count)

    @tile_wall.add_dora
    assert_equal(third_kong_count, @tile_wall.kong_count)
  end

  def test_add_open_dora_code_when_new_dora_tile_added
    before_open_dora_codes_size = @tile_wall.open_dora_codes.size
    @tile_wall.add_dora
    after_open_dora_codes_size = @tile_wall.open_dora_codes.size
    assert_equal(1, before_open_dora_codes_size)
    assert_equal(2, after_open_dora_codes_size)

    first_open_dora_tiles = @tile_wall.tiles.filter { |tile| tile.code == @tile_wall.open_dora_codes[0]}
    second_open_dora_tiles = @tile_wall.tiles.filter { |tile| tile.code == @tile_wall.open_dora_codes[1]}
    first_open_dora_checker = DORA_CHECKERS[@tile_wall.open_dora_indicators[0].name]
    second_open_dora_checker = DORA_CHECKERS[@tile_wall.open_dora_indicators[1].name]

    first_open_dora_tiles.each { |tile| assert_equal(first_open_dora_checker, tile.name) }
    second_open_dora_tiles.each { |tile| assert_equal(second_open_dora_checker, tile.name) }
  end

  def test_add_blind_dora_code_when_new_dora_tile_added
    before_blind_dora_codes_size = @tile_wall.blind_dora_codes.size
    @tile_wall.add_dora
    after_blind_dora_codes_size = @tile_wall.blind_dora_codes.size
    assert_equal(1, before_blind_dora_codes_size)
    assert_equal(2, after_blind_dora_codes_size)

    first_blind_dora_tiles = @tile_wall.tiles.filter { |tile| tile.code == @tile_wall.blind_dora_codes[0]}
    second_blind_dora_tiles = @tile_wall.tiles.filter { |tile| tile.code == @tile_wall.blind_dora_codes[1]}
    first_blind_dora_checker = DORA_CHECKERS[@tile_wall.blind_dora_indicators[0].name]
    second_blind_dora_checker = DORA_CHECKERS[@tile_wall.blind_dora_indicators[1].name]

    first_blind_dora_tiles.each { |tile| assert_equal(first_blind_dora_checker, tile.name) }
    second_blind_dora_tiles.each { |tile| assert_equal(second_blind_dora_checker, tile.name) }
  end

  def test_increase_open_dora_count_when_new_dora_tile_added
    @tile_wall.tiles.each do |tile|
      dora_count = tile.dora[:open][:count]

      if @tile_wall.open_dora_codes.include?(tile.code)
        assert_equal(1, dora_count)
      else
        assert_equal(0, dora_count)
      end
    end
  end

  def test_increase_blind_dora_count_when_new_dora_tile_added
    @tile_wall.tiles.each do |tile|
      dora_count = tile.dora[:blind][:count]

      if @tile_wall.blind_dora_codes.include?(tile.code)
        assert_equal(1, dora_count)
      else
        assert_equal(0, dora_count)
      end
    end
  end

  def test_can_not_add_dora_when_kong_count_is_5_or_more
    assert_equal(true, @tile_wall.can_kong?)
    max_kong_count = 4
    max_kong_count.times { assert_nothing_raised { @tile_wall.add_dora } }

    assert_equal(false, @tile_wall.can_kong?)
    assert_raise(StandardError) { @tile_wall.add_dora }
    assert_equal(max_kong_count, @tile_wall.kong_count)
  end
end
