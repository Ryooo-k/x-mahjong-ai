# frozen_string_literal: true
require 'debug'
require 'test/unit'
require_relative '../../src/domain/table'
require_relative '../util/file_loader'

class TableTest < Test::Unit::TestCase
  DORA_CODE_CHECKERS = {
    # 萬子 0〜8
    0 => 1,
    1 => 2,
    2 => 3,
    3 => 4,
    4 => 5,
    5 => 6,
    6 => 7,
    7 => 8,
    8 => 0, # 9萬 -> 1萬
  
    # 筒子 9〜17
    9  => 10,
    10 => 11,
    11 => 12,
    12 => 13,
    13 => 14,
    14 => 15,
    15 => 16,
    16 => 17,
    17 => 9, # 9筒 -> 1筒
  
    # 索子 18〜26
    18 => 19,
    19 => 20,
    20 => 21,
    21 => 22,
    22 => 23,
    23 => 24,
    24 => 25,
    25 => 26,
    26 => 18, # 9索 -> 1索
  
    # 字牌 27〜33
    27 => 28, # 東 -> 南
    28 => 29, # 南 -> 西
    29 => 30, # 西 -> 北
    30 => 27, # 北 -> 東
  
    31 => 32, # 白 -> 發
    32 => 33, # 發 -> 中
    33 => 31, # 中 -> 白
  }.freeze

  def setup
    @config = FileLoader.load_parameter
    @table = Table.new(@config['table'], @config['player'])
  end

  def test_table_initialize_game_mode_with_expected_name_and_end_round
    assert_equal '東南戦', @table.game_mode[:name]
    assert_equal 8, @table.game_mode[:end_round]
  end

  def test_table_initialize_attendance_with_expected_number
    assert_equal 4, @table.attendance
  end

  def test_red_dora_return_tile_names_and_ids
    assert_equal ['5萬', '5筒', '5索'], @table.red_dora[:names]
    assert_equal [19, 55, 91], @table.red_dora[:ids]
  end

  def test_table_initialize_tile_wall_with_expected_class
    tile_wall = TileWall.new
    assert_instance_of tile_wall.class, @table.tile_wall
  end

  def test_table_initialize_players_with_expected_class_and_number
    player_class = Player.new(0, @config['player']['agent']).class
    @table.players.each { |player| assert_instance_of(player_class, player) }
    assert_equal 4, @table.players.size
  end

  def test_table_initialize_round_with_expected_count_and_name
    assert_equal 0, @table.round[:count]
    assert_equal '東一局', @table.round[:name]
    assert_equal '1z', @table.round[:wind]
  end

  def test_table_initialize_honba_with_expected_count_and_name
    assert_equal 0, @table.honba[:count]
    assert_equal '〇本場', @table.honba[:name]
  end

  def test_wind_orders_return_players_in_east_to_north_order
    assert_equal @table.host, @table.wind_orders.first

    @table.proceed_to_next_round
    assert_equal @table.host, @table.wind_orders.first
  end

  def test_host_rotate_every_four_rounds_when_proceed_to_next_round
    assert_equal @table.host, @table.seat_orders[0]

    @table.proceed_to_next_round
    assert_equal @table.host, @table.seat_orders[1]

    @table.proceed_to_next_round
    assert_equal @table.host, @table.seat_orders[2]

    @table.proceed_to_next_round
    assert_equal @table.host, @table.seat_orders[3]

    @table.proceed_to_next_round
    assert_equal @table.host, @table.seat_orders[0]
  end

  def test_children_return_non_host
    assert_not_include @table.children, @table.host
  end

  def test_top_tile_return_tile_at_current_draw_count_position
    draw_count = @table.draw_count
    top_tile = @table.tile_wall.live_walls[draw_count]
    assert_equal top_tile, @table.top_tile
  end

  def test_remaining_tile_count
    expected = @table.tile_wall.live_walls.size
    assert_equal expected, @table.remaining_tile_count
  end

  def test_open_dora_indicators
    assert_equal 1, @table.open_dora_indicators.size
    @table.increase_kong_count
    assert_equal 2, @table.open_dora_indicators.size
  end

  def test_blind_dora_indicators
    first_open_dora_indicator = @table.tile_wall.open_dora_indicators.first
    assert_equal [first_open_dora_indicator], @table.open_dora_indicators

    @table.increase_kong_count
    second_open_dora_indicator = @table.tile_wall.open_dora_indicators[1]
    assert_equal [first_open_dora_indicator, second_open_dora_indicator], @table.open_dora_indicators
  end

  def test_open_dora_codes
    dora_codes = @table.open_dora_indicators.map { |indicator| DORA_CODE_CHECKERS[indicator.code] }
    assert_equal dora_codes, @table.open_dora_codes

    @table.increase_kong_count
    dora_codes = @table.open_dora_indicators.map { |indicator| DORA_CODE_CHECKERS[indicator.code] }
    assert_equal dora_codes, @table.open_dora_codes
  end

  def test_blind_dora_codes
    dora_codes =  @table.blind_dora_indicators.map { |indicator| DORA_CODE_CHECKERS[indicator.code] }
    assert_equal dora_codes, @table.blind_dora_codes

    @table.increase_kong_count
    dora_codes =  @table.blind_dora_indicators.map { |indicator| DORA_CODE_CHECKERS[indicator.code] }
    assert_equal dora_codes, @table.blind_dora_codes
  end

  def test_ranked_players
    first_player = @table.seat_orders[0]
    second_player = @table.seat_orders[1]
    third_player = @table.seat_orders[2]
    fourth_player = @table.seat_orders[3]
    assert_equal [first_player, second_player, third_player, fourth_player], @table.ranked_players

    first_player.award_point(-12_000)
    second_player.award_point(-8_000)
    third_player.award_point(8_000)
    fourth_player.award_point(12_000)
    assert_equal [fourth_player, third_player, second_player, first_player], @table.ranked_players

    first_player.award_point(24_000)
    assert_equal [first_player, fourth_player, third_player, second_player], @table.ranked_players
  end

  def test_restart
    @table.increase_draw_count
    @table.increase_kong_count
    old_tile_wall = @table.tile_wall.dup
    host = @table.host.dup

    @table.restart
    assert_not_equal old_tile_wall, @table.tile_wall
    assert_equal 0, @table.draw_count
    assert_equal 0, @table.kong_count
    assert_equal '東一局', @table.round[:name]
    assert_equal 1, @table.honba[:count]
    assert_equal '一本場', @table.honba[:name]
    assert_equal host.id, @table.host.id
  end

  def test_proceed_to_next_round
    @table.increase_draw_count
    @table.increase_kong_count
    old_host = @table.host.dup

    @table.proceed_to_next_round
    assert_equal 0, @table.draw_count
    assert_equal 0, @table.kong_count
    assert_equal 1, @table.round[:count]
    assert_equal '東二局', @table.round[:name]
    assert_equal '1z', @table.round[:wind]
    assert_equal 0, @table.honba[:count]
    assert_equal '〇本場', @table.honba[:name]
    assert_not_equal old_host.id, @table.host.id
  end

  def test_reset
    @table.proceed_to_next_round
    @table.restart
    @table.increase_draw_count
    @table.increase_kong_count
    old_seat_orders = @table.seat_orders.dup

    @table.reset
    assert_equal '東一局', @table.round[:name]
    assert_equal '〇本場', @table.honba[:name]
    assert_equal 0, @table.draw_count
    assert_equal 0, @table.kong_count
    assert_not_equal old_seat_orders, @table.seat_orders
  end
end
