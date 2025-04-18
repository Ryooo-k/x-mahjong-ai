# frozen_string_literal: true
require 'debug'
require 'test/unit'
require_relative '../../src/domain/table'
require_relative '../util/file_loader'

class TableTest < Test::Unit::TestCase
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
    @config = FileLoader.load_parameter
    @table = Table.new(@config['table'], @config['player'])
  end

  def test_table_initialize_game_mode_with_expected_name_and_end_round
    assert_equal('東南戦', @table.game_mode[:name])
    assert_equal(8, @table.game_mode[:end_round])
  end

  def test_table_initialize_attendance_with_expected_number
    assert_equal(@config['table']['attendance'], @table.attendance)
  end

  def test_red_dora_return_tile_names_and_ids
    assert_equal(['5萬', '5筒', '5索'], @table.red_dora[:names])
    assert_equal([19, 55, 91], @table.red_dora[:ids])
  end

  def test_table_initialize_tile_wall_with_expected_class
    tile_wall = TileWall.new
    assert_instance_of(tile_wall.class, @table.tile_wall)
  end

  def test_table_initialize_players_with_expected_class_and_number
    player_class = Player.new(0, @config['player']['discard_agent'], @config['player']['call_agent']).class
    @table.players.each { |player| assert_instance_of(player_class, player) }
    assert_equal(@config['table']['attendance'], @table.players.size)
  end

  def test_table_initialize_round_with_expected_count_and_name
    assert_equal(0, @table.round[:count])
    assert_equal('東一局', @table.round[:name])
  end

  def test_table_initialize_honba_with_expected_count_and_name
    assert_equal(0, @table.honba[:count])
    assert_equal('〇本場', @table.honba[:name])
  end

  def test_advance_round_and_restart_round_counter
    @table.advance_round
    assert_equal(1, @table.round[:count])
    assert_equal('東二局', @table.round[:name])

    @table.advance_round
    assert_equal(2, @table.round[:count])
    assert_equal('東三局', @table.round[:name])

    @table.advance_round
    assert_equal(3, @table.round[:count])
    assert_equal('東四局', @table.round[:name])

    @table.advance_round
    assert_equal(4, @table.round[:count])
    assert_equal('南一局', @table.round[:name])

    @table.reset
    assert_equal(0, @table.round[:count])
    assert_equal('東一局', @table.round[:name])
  end

  def test_increase_honba_and_restart_honba_counter
    @table.increase_honba
    assert_equal(1, @table.honba[:count])
    assert_equal('一本場', @table.honba[:name])

    @table.increase_honba
    assert_equal(2, @table.honba[:count])
    assert_equal('二本場', @table.honba[:name])

    @table.restart_honba_count
    assert_equal(0, @table.honba[:count])
    assert_equal('〇本場', @table.honba[:name])
  end

  def test_host_rotate_every_four_rounds
    assert_equal(@table.seat_orders[0], @table.host)

    @table.advance_round
    assert_equal(@table.seat_orders[1], @table.host)

    @table.advance_round
    assert_equal(@table.seat_orders[2], @table.host)

    @table.advance_round
    assert_equal(@table.seat_orders[3], @table.host)

    @table.advance_round
    assert_equal(@table.seat_orders[0], @table.host)
  end

  def test_wind_orders_return_players_in_east_to_north_order
    assert_equal(@table.host, @table.wind_orders.first)

    @table.advance_round
    assert_equal(@table.host, @table.wind_orders.first)
  end

  def test_children_return_non_host
    assert_not_include(@table.children, @table.host)
  end

  def test_top_tile_return_tile_at_current_draw_count_position
    current_draw_count = @table.draw_count
    top_tile = @table.tile_wall.live_walls[current_draw_count]
    assert_equal(top_tile, @table.top_tile)
  end

  def test_remaining_tile_count
    expected = @table.tile_wall.live_walls.size
    assert_equal(expected, @table.remaining_tile_count)
  end

  def test_open_dora_tile_return_expected_dora_tile
    open_dora_indicators = @table.tile_wall.open_dora_indicators
    dora_names = open_dora_indicators.map { |indicator| DORA_CHECKERS[indicator.name] }
    assert_equal(dora_names[0], @table.open_dora_tiles.first.name)

    @table.increase_kong_count
    assert_equal(dora_names[1], @table.open_dora_tiles.last.name)

    @table.increase_kong_count
    assert_equal(dora_names[2], @table.open_dora_tiles.last.name)

    @table.increase_kong_count
    assert_equal(dora_names[3], @table.open_dora_tiles.last.name)

    @table.increase_kong_count
    assert_equal(dora_names[4], @table.open_dora_tiles.last.name)
  end

  def test_blind_dora_tile_return_expected_dora_tile
    blind_dora_indicators = @table.tile_wall.blind_dora_indicators
    dora_names = blind_dora_indicators.map { |indicator| DORA_CHECKERS[indicator.name] }
    assert_equal(dora_names[0], @table.blind_dora_tiles.first.name)

    @table.increase_kong_count
    assert_equal(dora_names[1], @table.blind_dora_tiles.last.name)

    @table.increase_kong_count
    assert_equal(dora_names[2], @table.blind_dora_tiles.last.name)

    @table.increase_kong_count
    assert_equal(dora_names[3], @table.blind_dora_tiles.last.name)

    @table.increase_kong_count
    assert_equal(dora_names[4], @table.blind_dora_tiles.last.name)
  end

  def test_deal_starting_hand
    live_walls = @table.tile_wall.live_walls
    east_player_hands = live_walls[0..12]
    south_player_hands = live_walls[13..25]
    west_player_hands = live_walls[26..38]
    north_player_hands = live_walls[39..51]
    @table.deal_starting_hand
    players = @table.wind_orders

    assert_equal(east_player_hands, players[0].hands)
    assert_equal(south_player_hands, players[1].hands)
    assert_equal(west_player_hands, players[2].hands)
    assert_equal(north_player_hands, players[3].hands)
  end

  def test_reset
    @table.advance_round
    @table.increase_honba
    old_host = @table.host.dup
    old_round = @table.round.dup
    old_honba = @table.honba.dup
    old_draw_count = @table.draw_count.dup

    @table.reset
    assert_not_equal(old_host, @table.host)
    assert_not_equal(old_round, @table.round)
    assert_not_equal(old_honba, @table.honba)
    assert_not_equal(old_draw_count, @table.draw_count)
  end
end
