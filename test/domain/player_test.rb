# frozen_string_literal: true

require 'test/unit'
require_relative '../../src/domain/player'
require_relative '../../src/domain/tile'

class PlayerTest < Test::Unit::TestCase
  def setup
    @player = Player.new(0)
    @other_player = Player.new(1)
    @manzu_1_tile = Tile.new(0)
    @manzu_2_tile = Tile.new(4)
    @manzu_3_tile_id8 = Tile.new(8)
    @manzu_3_tile_id9 = Tile.new(9)
    @manzu_3_tile_id10 = Tile.new(10)
    @manzu_3_tile_id11 = Tile.new(11)
    @east_tile = Tile.new(108)
  end

  def test_initialize_player
    expected = {
      score: 25_000,
      point_histories: [],
      hands: { tiles: [], ids: [], suits: [], numbers: [], codes: [], names: []},
      hand_histories: [],
      called_tile_table: [],
      rivers: []
    }

    assert_equal(expected[:score], @player.score)
    assert_equal(expected[:point_histories], @player.point_histories)
    assert_equal(expected[:hands], @player.hands)
    assert_equal(expected[:hand_histories], @player.hand_histories)
    assert_equal(expected[:called_tile_table], @player.called_tile_table)
    assert_equal(expected[:rivers], @player.rivers)
  end

  def test_add_tile_to_hands_when_player_drew_tile
    @player.draw(@manzu_1_tile)
    assert_equal(@manzu_1_tile, @player.hands[:tiles].first)
    assert_equal(@manzu_1_tile.id, @player.hands[:ids].first)
    assert_equal(@manzu_1_tile.suit, @player.hands[:suits].first)
    assert_equal(@manzu_1_tile.number, @player.hands[:numbers].first)
    assert_equal(@manzu_1_tile.code, @player.hands[:codes].first)
    assert_equal(@manzu_1_tile.name, @player.hands[:names].first)
  end

  def test_holder_is_set_when_player_drew_tile
    @player.draw(@manzu_1_tile)
    assert_equal(@player, @manzu_1_tile.holder)
  end

  def test_hands_return_hand_state
    @player.draw(@manzu_1_tile)
    @player.draw(@manzu_2_tile)
    expected = {
      tiles: [@manzu_1_tile, @manzu_2_tile],
      ids: [@manzu_1_tile.id, @manzu_2_tile.id],
      suits: [@manzu_1_tile.suit, @manzu_2_tile.suit],
      numbers: [@manzu_1_tile.number, @manzu_2_tile.number],
      codes: [@manzu_1_tile.code, @manzu_2_tile.code],
      names: [@manzu_1_tile.name, @manzu_2_tile.name]
    }
    assert_equal(expected, @player.hands)
  end

  def test_sorted_hands_return_hands_sorted_by_id
    @player.draw(@east_tile)
    @player.draw(@manzu_2_tile)
    @player.draw(@manzu_1_tile)
    assert_equal(['東', '2萬','1萬'], @player.hands[:names])
    assert_equal(['1萬', '2萬', '東'], @player.sorted_hands[:names])
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
    @player.draw(@manzu_1_tile)
    @player.draw(@manzu_2_tile)
    @player.record_hands
    assert_equal([[@manzu_1_tile, @manzu_2_tile]], @player.hand_histories)

    @player.play(@manzu_2_tile)
    assert_equal([[@manzu_1_tile, @manzu_2_tile], [@manzu_1_tile]], @player.hand_histories)
  end

  # playメソッドのテスト
  def test_remove_tile_from_hand_when_player_played_tile
    @player.draw(@manzu_1_tile)
    @player.draw(@manzu_2_tile)

    @player.play(@manzu_1_tile)
    assert_equal([@manzu_2_tile], @player.hands[:tiles])
  end

  def test_add_tile_from_river_when_player_played_tile
    assert_equal([], @player.rivers)
    @player.draw(@manzu_1_tile)
    @player.play(@manzu_1_tile)
    assert_equal([@manzu_1_tile], @player.rivers)
  end

  def test_add_tile_from_hand_histories_when_player_played_tile
    @player.draw(@manzu_1_tile)
    @player.draw(@manzu_2_tile)
    @player.draw(@east_tile)
    @player.play(@east_tile)
    assert_equal([[@manzu_1_tile, @manzu_2_tile]], @player.hand_histories)

    @player.play(@manzu_1_tile)
    assert_equal([[@manzu_1_tile, @manzu_2_tile], [@manzu_2_tile]], @player.hand_histories)
  end

  def test_can_not_play_when_tile_not_in_hand
    error = assert_raise(ArgumentError) { @player.play(@manzu_1_tile) }
    assert_equal('手牌に無い牌は選択できません。', error.message)
  end

  # pongメソッドのテスト
  def test_tile_holder_change_to_pong_player
    @other_player.draw(@manzu_3_tile_id8)
    assert_equal(@other_player, @manzu_3_tile_id8.holder)

    combinations = [@manzu_3_tile_id9, @manzu_3_tile_id10]
    @player.draw(@manzu_3_tile_id9)
    @player.draw(@manzu_3_tile_id10)
    @player.pong(combinations, @manzu_3_tile_id8)
    assert_equal(@player, @manzu_3_tile_id8.holder)
  end

  def test_hands_delete_target_tiles_when_player_called_pong
    target = @manzu_3_tile_id8
    combinations = [@manzu_3_tile_id9, @manzu_3_tile_id10]
    @player.draw(@manzu_1_tile)
    @player.draw(@manzu_3_tile_id9)
    @player.draw(@manzu_3_tile_id10)
    @player.pong(combinations, target)

    called_tile_table = combinations << target
    @player.hands[:tiles].each { |tile| assert_not_include(called_tile_table, tile) }
  end

  def test_called_tile_table_add_target_tiles_when_player_called_pong
    target = @manzu_3_tile_id8
    combinations = [@manzu_3_tile_id9, @manzu_3_tile_id10]
    @player.draw(@manzu_3_tile_id9)
    @player.draw(@manzu_3_tile_id10)
    @player.pong(combinations, target)

    called_tile_table = combinations << target
    assert_equal([called_tile_table], @player.called_tile_table)
  end

  def test_can_not_call_pong_when_combinations_not_in_hand
    combinations = [@manzu_3_tile_id9, @manzu_3_tile_id10]
    error = assert_raise(ArgumentError) { @player.pong(combinations, @manzu_3_tile_id8) }
    assert_equal('有効な牌が無いためポンできません。', error.message)
  end

  # chowメソッドのテスト
  def test_can_not_call_chow_when_combinations_not_in_hand
    combinations = [@manzu_1_tile, @manzu_2_tile]
    error = assert_raise(ArgumentError) { @player.chow(combinations, @manzu_3_tile_id8) }
    assert_equal('有効な牌が無いためチーできません。', error.message)
  end

  # concealed_kongメソッドのテスト
  def test_hands_delete_target_tiles_when_player_called_concealed_kong
    @player.draw(@manzu_3_tile_id8)
    @player.draw(@manzu_3_tile_id9)
    @player.draw(@manzu_3_tile_id10)
    @player.draw(@manzu_3_tile_id11)
    @player.draw(@east_tile)
    combinations = [@manzu_3_tile_id8, @manzu_3_tile_id9, @manzu_3_tile_id10, @manzu_3_tile_id11]
    @player.concealed_kong(combinations)
    @player.hands[:tiles].each { |tile| assert_not_include(combinations, tile) }
  end

  def test_called_tile_table_add_target_tiles_when_player_called_concealed_kong
    @player.draw(@manzu_3_tile_id8)
    @player.draw(@manzu_3_tile_id9)
    @player.draw(@manzu_3_tile_id10)
    @player.draw(@manzu_3_tile_id11)
    @player.draw(@east_tile)
    combinations = [@manzu_3_tile_id8, @manzu_3_tile_id9, @manzu_3_tile_id10, @manzu_3_tile_id11]
    @player.concealed_kong(combinations)
    assert_equal([combinations], @player.called_tile_table)
  end

  def test_can_not_call_concealed_kong_when_combinations_not_in_hand
    combinations = [@manzu_3_tile_id8, @manzu_3_tile_id9, @manzu_3_tile_id10, @manzu_3_tile_id11]
    error = assert_raise(ArgumentError) { @player.concealed_kong(combinations) }
    assert_equal('有効な牌が無いため暗カンできません。', error.message)
  end

  # open_kongメソッドのテスト
  def test_can_not_call_open_kong_when_combinations_not_in_hand
    target = @manzu_3_tile_id11
    combinations = [@manzu_3_tile_id8, @manzu_3_tile_id9, @manzu_3_tile_id10]
    error = assert_raise(ArgumentError) { @player.open_kong(combinations, target) }
    assert_equal('有効な牌が無いため大明カンできません。', error.message)
  end

  # extended_kongメソッドのテスト
  def test_called_tile_table_add_target_tile_when_player_called_extended_kong
    combinations = [@manzu_3_tile_id8, @manzu_3_tile_id9]
    @player.draw(@manzu_3_tile_id8)
    @player.draw(@manzu_3_tile_id9)
    @player.pong(combinations, @manzu_3_tile_id10)
    @player.extended_kong(@manzu_3_tile_id11)

    expected = [[@manzu_3_tile_id8, @manzu_3_tile_id9, @manzu_3_tile_id10, @manzu_3_tile_id11]]
    assert_equal(expected, @player.called_tile_table)
  end

  def test_can_not_call_extended_kong_when_no_existing_pong
    error = assert_raise(ArgumentError) { @player.extended_kong(@manzu_3_tile_id8) }
    assert_equal('有効な牌が無いため加カンできません。', error.message)
  end

  def test_reset
    @player.draw(@manzu_1_tile)
    @player.draw(@manzu_2_tile)
    @player.draw(@east_tile)
    @player.record_hands
    @player.play(@east_tile)
    @player.add_point(8_000)
    @player.chow([@manzu_1_tile, @manzu_2_tile], @manzu_3_tile_id10)

    @player.reset
    assert_equal(25_000, @player.score)
    assert_equal([], @player.point_histories)
    assert_equal([], @player.hands[:tiles])
    assert_equal([], @player.hand_histories)
    assert_equal([], @player.called_tile_table)
    assert_equal([], @player.rivers)
  end
end
