# frozen_string_literal: true

require 'test/unit'
require_relative '../../src/domain/player'
require_relative '../../src/domain/tile'
require_relative '../util/file_loader'

class PlayerTest < Test::Unit::TestCase
  def setup
    @config = FileLoader.load_parameter
    @player = Player.new(0, @config['player']['discard_agent'], @config['player']['call_agent'])
    @other_player = Player.new(1, @config['player']['discard_agent'], @config['player']['call_agent'])
    @manzu_1 = Tile.new(0)
    @manzu_2 = Tile.new(4)
    @manzu_3_id8 = Tile.new(8)
    @manzu_3_id9 = Tile.new(9)
    @manzu_3_id10 = Tile.new(10)
    @manzu_3_id11 = Tile.new(11)
    @east = Tile.new(108)
  end

  def test_player_initialization
    assert_equal(25_000, @player.score)
    assert_equal([], @player.point_histories)
    assert_equal([], @player.hands)
    assert_equal([], @player.hand_histories)
    assert_equal([[], [], [], []], @player.called_tile_table)
    assert_equal([], @player.rivers)
  end

  def test_add_tile_to_hands_when_player_drew_tile
    @player.draw(@manzu_1)
    assert_equal(@manzu_1, @player.hands.first)
  end

  def test_holder_is_set_when_player_drew_tile
    @player.draw(@manzu_1)
    assert_equal(@player, @manzu_1.holder)
  end

  def test_hands_return_tiles
    @player.draw(@manzu_1)
    @player.draw(@manzu_2)
    assert_equal([@manzu_1, @manzu_2], @player.hands)
  end

  def test_sorted_hands_return_hands_sorted_by_id
    @player.draw(@east)
    @player.draw(@manzu_2)
    @player.draw(@manzu_1)
    assert_equal([@east, @manzu_2, @manzu_1], @player.hands)
    assert_equal([@manzu_1, @manzu_2, @east], @player.sorted_hands)
  end

  def test_score_increase_with_added_point
    assert_equal(25_000, @player.score)
  
    @player.add_point(8_000)
    assert_equal(33_000, @player.score)
    assert_equal([8_000], @player.point_histories)
  
    @player.add_point(-12_000)
    assert_equal(21_000, @player.score)
    assert_equal([8_000, -12_000], @player.point_histories)
  end

  def test_record_hands
    @player.draw(@manzu_1)
    @player.draw(@manzu_2)
    @player.record_hands
    assert_equal([[@manzu_1, @manzu_2]], @player.hand_histories)
  end

  def test_remove_tile_from_hand_when_player_discarded_tile
    @player.draw(@manzu_1)
    @player.draw(@manzu_2)
    assert_equal([@manzu_1, @manzu_2], @player.hands)

    @player.discard(@manzu_1)
    assert_equal([@manzu_2], @player.hands)
  end

  def test_add_tile_from_river_when_player_discarded_tile
    assert_equal([], @player.rivers)
    @player.draw(@manzu_1)
    @player.discard(@manzu_1)
    assert_equal([@manzu_1], @player.rivers)
  end

  def test_add_tile_from_hand_histories_when_player_discarded_tile
    @player.draw(@manzu_1)
    @player.draw(@manzu_2)
    @player.draw(@east)
    @player.discard(@east)
    assert_equal([[@manzu_1, @manzu_2]], @player.hand_histories)

    @player.discard(@manzu_1)
    assert_equal([[@manzu_1, @manzu_2], [@manzu_2]], @player.hand_histories)
  end

  def test_can_not_discard_when_tile_not_in_hand
    error = assert_raise(ArgumentError) { @player.discard(@manzu_1) }
    assert_equal('手牌に無い牌は選択できません。', error.message)
  end

  def test_tile_holder_change_to_pong_player
    @other_player.draw(@manzu_3_id8)
    assert_equal(@other_player, @manzu_3_id8.holder)

    combinations = [@manzu_3_id9, @manzu_3_id10]
    @player.draw(@manzu_3_id9)
    @player.draw(@manzu_3_id10)
    @player.pong(combinations, @manzu_3_id8)
    assert_equal(@player, @manzu_3_id8.holder)
  end

  def test_hands_delete_target_tiles_when_player_called_pong
    target = @manzu_3_id8
    combinations = [@manzu_3_id9, @manzu_3_id10]
    @player.draw(@manzu_1)
    @player.draw(@manzu_3_id9)
    @player.draw(@manzu_3_id10)
    @player.pong(combinations, target)

    called_tiles = combinations << target
    @player.hands.each { |tile| assert_not_include(called_tiles, tile) }
  end

  def test_called_tile_table_add_target_tiles_when_player_called_pong
    target = @manzu_3_id8
    combinations = [@manzu_3_id9, @manzu_3_id10]
    @player.draw(@manzu_3_id9)
    @player.draw(@manzu_3_id10)
    @player.pong(combinations, target)

    called_tiles = combinations << target
    assert_equal([called_tiles, [], [], []], @player.called_tile_table)

    combinations = [@manzu_3_id9, @manzu_3_id10]
    @player.draw(@manzu_3_id9)
    @player.draw(@manzu_3_id10)
    @player.pong(combinations, target)
    assert_equal([called_tiles, called_tiles, [], []], @player.called_tile_table)
  end

  def test_can_not_call_pong_when_combinations_not_in_hand
    combinations = [@manzu_3_id9, @manzu_3_id10]
    error = assert_raise(ArgumentError) { @player.pong(combinations, @manzu_3_id8) }
    assert_equal('有効な牌が無いためポンできません。', error.message)
  end

  def test_can_not_call_chow_when_combinations_not_in_hand
    combinations = [@manzu_1, @manzu_2]
    error = assert_raise(ArgumentError) { @player.chow(combinations, @manzu_3_id8) }
    assert_equal('有効な牌が無いためチーできません。', error.message)
  end

  def test_hands_delete_target_tiles_when_player_called_concealed_kong
    @player.draw(@manzu_3_id8)
    @player.draw(@manzu_3_id9)
    @player.draw(@manzu_3_id10)
    @player.draw(@manzu_3_id11)
    @player.draw(@east)
    combinations = [@manzu_3_id8, @manzu_3_id9, @manzu_3_id10, @manzu_3_id11]
    @player.concealed_kong(combinations)
    @player.hands.each { |tile| assert_not_include(combinations, tile) }
  end

  def test_called_tile_table_add_target_tiles_when_player_called_concealed_kong
    @player.draw(@manzu_3_id8)
    @player.draw(@manzu_3_id9)
    @player.draw(@manzu_3_id10)
    @player.draw(@manzu_3_id11)
    @player.draw(@east)
    combinations = [@manzu_3_id8, @manzu_3_id9, @manzu_3_id10, @manzu_3_id11]
    @player.concealed_kong(combinations)
    assert_equal([combinations, [], [], []], @player.called_tile_table)
  end

  def test_can_not_call_concealed_kong_when_combinations_not_in_hand
    combinations = [@manzu_3_id8, @manzu_3_id9, @manzu_3_id10, @manzu_3_id11]
    error = assert_raise(ArgumentError) { @player.concealed_kong(combinations) }
    assert_equal('有効な牌が無いため暗カンできません。', error.message)
  end

  def test_can_not_call_open_kong_when_combinations_not_in_hand
    target = @manzu_3_id11
    combinations = [@manzu_3_id8, @manzu_3_id9, @manzu_3_id10]
    error = assert_raise(ArgumentError) { @player.open_kong(combinations, target) }
    assert_equal('有効な牌が無いため大明カンできません。', error.message)
  end

  def test_called_tile_table_add_target_tile_when_player_called_extended_kong
    combinations = [@manzu_3_id8, @manzu_3_id9]
    @player.draw(@manzu_3_id8)
    @player.draw(@manzu_3_id9)
    @player.pong(combinations, @manzu_3_id10)
    @player.extended_kong(@manzu_3_id11)

    expected = [[@manzu_3_id8, @manzu_3_id9, @manzu_3_id10, @manzu_3_id11], [], [], []]
    assert_equal(expected, @player.called_tile_table)
  end

  def test_can_not_call_extended_kong_when_no_existing_pong
    error = assert_raise(ArgumentError) { @player.extended_kong(@manzu_3_id8) }
    assert_equal('有効な牌が無いため加カンできません。', error.message)
  end

  def test_reset
    @player.draw(@manzu_1)
    @player.draw(@manzu_2)
    @player.draw(@east)
    @player.record_hands
    @player.discard(@east)
    @player.add_point(8_000)
    @player.chow([@manzu_1, @manzu_2], @manzu_3_id10)

    @player.reset
    assert_equal(25_000, @player.score)
    assert_equal([], @player.point_histories)
    assert_equal([], @player.hands)
    assert_equal([], @player.hand_histories)
    assert_equal([[], [], [], []], @player.called_tile_table)
    assert_equal([], @player.rivers)
  end
end
