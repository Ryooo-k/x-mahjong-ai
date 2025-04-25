# frozen_string_literal: true
require 'debug'
require 'test/unit'
require_relative '../../src/environment/env'
require_relative '../util/file_loader'

class EnvTest < Test::Unit::TestCase
  def setup
    parameter = FileLoader.load_parameter
    @env = Env.new(parameter['table'], parameter['player'])
  end

  def test_player_draw
    first_tile = @env.table.tile_wall.live_walls[0]
    second_tile = @env.table.tile_wall.live_walls[1]
    @env.player_draw
    assert_equal [first_tile], @env.current_player.hands
    assert_equal 1, @env.table.draw_count

    @env.player_draw
    assert_equal [first_tile, second_tile], @env.current_player.hands
    assert_equal 2, @env.table.draw_count
  end

  def test_can_not_player_draw_when_game_over
    122.times { |_| @env.player_draw }
    result = @env.player_draw
    assert_equal nil, result
  end

  def test_step_return_done_false_and_reward_and_discarded_tile_when_not_agari_or_game_over
    15.times { |_| @env.player_draw }
    target_tile = @env.current_player.hands.first
    @env.current_player.discard(target_tile)

    action = 0
    expected_tile = @env.current_player.hands[action]
    _, reward, done, discarded_tile  = @env.step(action)
    assert_equal false, done
    assert_equal Integer, reward.class
    assert_equal expected_tile, discarded_tile
  end

  def test_step_return_done_true_and_minus_100_reward_discarded_tile_when_game_over
    13.times { |_| @env.player_draw } # 配牌を受け取る
    109.times do |_|
      @env.player_draw
      target_tile = @env.current_player.hands.first
      @env.current_player.discard(target_tile)
    end # ゲーム終了までツモる

    action = 2
    expected_tile = @env.current_player.hands[action]
    _, reward, done, discarded_tile  = @env.step(action)
    assert_equal true, done
    assert_equal -100, reward
    assert_equal expected_tile, discarded_tile
  end

  def test_rotate_turn
    current_player = @env.current_player.dup
    other_players = @env.other_players.dup
    @env.rotate_turn
    assert_not_equal current_player, @env.current_player
    assert_not_equal other_players, @env.other_players
  end
end
