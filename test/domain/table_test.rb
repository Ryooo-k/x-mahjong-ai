# frozen_string_literal: true

require 'test/unit'
require_relative '../../src/domain/table'

class TableTest < Test::Unit::TestCase
  def setup
    @mode_id = 1
    @attendance = 4
    @red_dora_mode_id = 1
    @table = Table.new(@mode_id, @attendance, @red_dora_mode_id)
  end

  def test_initialize_game_mode
    game_mode = { name: '東南戦', end_round: 8 }
    assert_equal(game_mode, @table.game_mode)
  end

  def test_initialize_attendance
    assert_equal(@attendance, @table.attendance)
  end

  def test_initialize_red_dora_tiles
    red_dora_tile_names = ['5萬', '5筒', '5索']
    assert_equal(red_dora_tile_names, @table.red_dora[:name])
  end

  def test_initialize_red_dora_tile_ids
    red_dora_tile_ids = [19, 55, 91]
    assert_equal(red_dora_tile_ids, @table.red_dora[:ids])
  end

  def test_initialize_tile_wall
    tile_wall = TileWall.new
    assert_instance_of(tile_wall.class, @table.tile_wall)
  end

  def test_initialize_players
    id = 0
    test_player = Player.new(id)

    assert_equal(@attendance, @table.players.size)
    @table.players.each { |player| assert_instance_of(test_player.class, player) }
  end

  def test_initialize_round
    round_counter = 0
    round_name = '東一局'

    assert_equal(round_counter, @table.round[:count])
    assert_equal(round_name, @table.round[:name])
  end

  def test_initialize_honba
    honba_counter = 0
    assert_equal(honba_counter, @table.honba[:count])
  end

  def test_advance_round_and_restart_round_counter
    next_round_counter = 1
    next_round_name = '東二局'
    @table.advance_round
    assert_equal(next_round_counter, @table.round[:count])
    assert_equal(next_round_name, @table.round[:name])

    next_next_round_counter = 2
    next_next_round_name = '東三局'
    @table.advance_round
    assert_equal(next_next_round_counter, @table.round[:count])
    assert_equal(next_next_round_name, @table.round[:name])

    round_counter = 0
    round_name = '東一局'
    @table.restart_round_count
    assert_equal(round_counter, @table.round[:count])
    assert_equal(round_name, @table.round[:name])
  end

  def test_increase_honba_and_restart_honba_counter
    next_honba_counter = 1
    next_honba_name = '一本場'
    @table.increase_honba
    assert_equal(next_honba_counter, @table.honba[:count])
    assert_equal(next_honba_name, @table.honba[:name])

    next_next_honba_counter = 2
    next_next_honba_name = '二本場'
    @table.increase_honba
    assert_equal(next_next_honba_counter, @table.honba[:count])
    assert_equal(next_next_honba_name, @table.honba[:name])

    honba_counter = 0
    honba_name = '〇本場'
    @table.restart_honba_count
    assert_equal(honba_counter, @table.honba[:count])
    assert_equal(honba_name, @table.honba[:name])
  end

  def test_host_rotate_every_four_rounds
    assert_equal(@table.host, @table.seat_orders[0])

    @table.advance_round
    assert_equal(@table.host, @table.seat_orders[1])

    @table.advance_round
    assert_equal(@table.host, @table.seat_orders[2])

    @table.advance_round
    assert_equal(@table.host, @table.seat_orders[3])

    @table.advance_round
    assert_equal(@table.host, @table.seat_orders[0])
  end

  def test_wind_orders_return_players_in_east_to_north_order
    assert_equal(@table.host, @table.wind_orders.first)

    @table.advance_round
    assert_equal(@table.host, @table.wind_orders.first)
  end

  def test_children_return_non_host
    assert_not_include(@table.children, @table.host)
  end

  def test_deal_starting_hand
    live_walls = @table.tile_wall.live_walls
    first_player_hands = live_walls[0..12]
    second_player_hands = live_walls[13..25]
    third_player_hands = live_walls[26..38]
    fourth_player_hands = live_walls[39..51]
    @table.deal_starting_hand
    players = @table.wind_orders

    assert_equal(first_player_hands, players[0].hands[:tiles])
    assert_equal(second_player_hands, players[1].hands[:tiles])
    assert_equal(third_player_hands, players[2].hands[:tiles])
    assert_equal(fourth_player_hands, players[3].hands[:tiles])
  end

  def test_reset
    @table.increase_honba
    @table.advance_round
    old_honba = @table.honba.dup
    old_round = @table.round.dup
    old_host = @table.host.dup
    @table.reset
    assert_not_equal(old_host, @table.host) # 前回と同じhostになる可能性もあるため一定確率でテストが落ちる
    assert_not_equal(old_honba, @table.honba)
    assert_not_equal(old_round, @table.round)
  end
end
