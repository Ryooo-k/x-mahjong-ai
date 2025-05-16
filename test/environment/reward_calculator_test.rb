# frozen_string_literal: true

require 'test/unit'
require_relative '../util/file_loader'
require_relative '../../src/environment/reward_calculator'
require_relative '../../src/domain/player'

class RewardCalculatorTest < Test::Unit::TestCase
  def setup
    config = FileLoader.load_parameter
    @player = Player.new(0, config['player']['agent'])
  end

  def test_calculate_round_over_reward_return_30_when_player_rank_1
    @player.instance_variable_set(:@rank, 1)
    @player.instance_variable_set(:@score, 0)

    reward = RewardCalculator.calculate_round_over_reward(@player)
    assert_equal 30, reward
  end

  def test_calculate_round_over_reward_return_10_when_player_rank_2
    @player.instance_variable_set(:@rank, 2)
    @player.instance_variable_set(:@score, 0)

    reward = RewardCalculator.calculate_round_over_reward(@player)
    assert_equal 10, reward
  end

  def test_calculate_round_over_reward_return_minus_10_when_player_rank_3
    @player.instance_variable_set(:@rank, 3)
    @player.instance_variable_set(:@score, 0)

    reward = RewardCalculator.calculate_round_over_reward(@player)
    assert_equal -10, reward
  end

  def test_calculate_round_over_reward_return_minus_30_when_player_rank_4
    @player.instance_variable_set(:@rank, 4)
    @player.instance_variable_set(:@score, 0)

    reward = RewardCalculator.calculate_round_over_reward(@player)
    assert_equal -30, reward
  end

  def test_calculate_round_over_reward_return_34_2_when_player_rank_1_and_score_42000
    @player.instance_variable_set(:@rank, 1)
    @player.instance_variable_set(:@score, 42000)

    reward = RewardCalculator.calculate_round_over_reward(@player)
    assert_equal 34.2, reward
  end

  def test_calculate_round_continue_reward_return_1_when_shanten_decrease
    @player.instance_variable_set(:@shanten_histories, [3, 2])
    @player.instance_variable_set(:@outs_histories, [32, 16])

    reward = RewardCalculator.calculate_round_continue_reward(@player)
    assert_equal 1, reward
  end

  def test_calculate_round_continue_reward_return_1_when_keeping_tenpai
    @player.instance_variable_set(:@shanten_histories, [0, 0])
    @player.instance_variable_set(:@outs_histories, [4, 4])

    reward = RewardCalculator.calculate_round_continue_reward(@player)
    assert_equal 1, reward
  end

  def test_calculate_round_continue_reward_return_1_when_outs_increase
    @player.instance_variable_set(:@shanten_histories, [3, 3])
    @player.instance_variable_set(:@outs_histories, [16, 32])

    reward = RewardCalculator.calculate_round_continue_reward(@player)
    assert_equal 1, reward
  end

  def test_calculate_round_continue_reward_return_0_when_keeping_shanten_and_outs
    @player.instance_variable_set(:@shanten_histories, [3, 3])
    @player.instance_variable_set(:@outs_histories, [16, 16])

    reward = RewardCalculator.calculate_round_continue_reward(@player)
    assert_equal 0, reward
  end

  def test_calculate_round_continue_reward_return_minus_1_when_shanten_increase
    @player.instance_variable_set(:@shanten_histories, [3, 4])
    @player.instance_variable_set(:@outs_histories, [32, 48])

    reward = RewardCalculator.calculate_round_continue_reward(@player)
    assert_equal -1, reward
  end
end
