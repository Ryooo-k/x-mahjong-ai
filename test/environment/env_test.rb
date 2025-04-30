# frozen_string_literal: true
require 'debug'
require 'test/unit'
require_relative '../../src/environment/env'
require_relative '../../src/domain/logic/hand_evaluator'
require_relative '../util/file_loader'

class EnvTest < Test::Unit::TestCase
  def setup
    @tiles = Array.new(136) { |id| Tile.new(id) }
    parameter = FileLoader.load_parameter
    @env = Env.new(parameter['table'], parameter['player'])
  end

  def test_player_draw
    top_tile = @env.table.top_tile
    before_draw_count = @env.table.draw_count
    @env.player_draw
    assert_equal top_tile, @env.current_player.hands.last
    assert_equal before_draw_count + 1, @env.table.draw_count
  end

  def test_can_not_player_draw_when_game_over
    122.times { |_| @env.player_draw }
    result = @env.player_draw
    assert_equal nil, result
  end

  def test_rotate_turn
    current_player = @env.current_player.dup
    other_players = @env.other_players.dup
    @env.rotate_turn
    assert_not_equal current_player, @env.current_player
    assert_not_equal other_players, @env.other_players
  end

  def test_update_triggered_by_game_over
    70.times do |_|
      @env.player_draw
      target_tile = @env.current_player.hands.first
      @env.current_player.discard(target_tile)
    end # ゲーム終了までツモる

    action = 0
    expected_tile = @env.current_player.sorted_hands[action]
    _, reward, done, discarded_tile  = @env.step(action)
    assert_equal -100, reward
    assert_equal true, done
    assert_equal expected_tile, discarded_tile
  end

  def test_update_triggered_by_shanten_decrease
    # 123456萬 123筒 78索 東 南
    hands = [
      @tiles[0], @tiles[4], @tiles[8], @tiles[12], @tiles[16], @tiles[20],
      @tiles[36], @tiles[40], @tiles[44],
      @tiles[96], @tiles[100],
      @tiles[108], @tiles[113]
    ]

    @env.current_player.instance_variable_set(:@hands, hands)
    old_shanten = @env.current_player.shanten_histories.last
    old_outs = @env.current_player.outs_histories.last

    @env.current_player.draw(@tiles[109]) # 東を引いて聴牌形にする
    _, reward, done, discarded_tile = @env.step(13) # 南(index=13)を捨て聴牌にする
    new_shanten = @env.current_player.shanten_histories.last
    new_outs = @env.current_player.outs_histories.last

    assert_equal true, new_shanten < old_shanten
    assert_equal true, new_outs < old_outs
    assert_equal reward, 50 # 向聴数が減った時の報酬と一致する
    assert_equal done, false
    assert_equal discarded_tile, @tiles[113]
  end

  def test_update_triggered_by_agari
    # 123456萬 123筒 789索 東東
    agari_hands = [
      @tiles[0], @tiles[4], @tiles[8], @tiles[12], @tiles[16], @tiles[20],
      @tiles[36], @tiles[40], @tiles[44],
      @tiles[96], @tiles[100], @tiles[104],
      @tiles[108], @tiles[109]
    ]

    @env.current_player.instance_variable_set(:@hands, agari_hands)
    _, reward, done, discarded_tile = @env.step(0)

    assert_equal -1, @env.current_player.shanten_histories.last
    assert_equal 0, @env.current_player.outs_histories.last
    assert_equal reward, 100 # 和了時の報酬と一致する
    assert_equal done, true
    assert_equal discarded_tile, nil
  end
end
