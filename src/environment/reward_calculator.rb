# frozen_string_literal: true

require_relative '../domain/logic/hand_evaluator'

module RewardCalculator
  REWARDS_BY_RANK = {
    1 => 30.0,
    2 => 10.0,
    3 => -10.0,
    4 => -30.0
  }
  NORMALIZATION_BASE_POINT = 10_000.0

  class << self
    def calculate_tsumo_rewards(current_player, other_players, round_over)
      all_players = [current_player] + other_players
      round_over ? calculate_round_over_rewards(all_players) : [0] * 4
    end

    def calculate_discard_rewards(current_player, other_players, round_over)
      all_players = [current_player] + other_players

      if round_over
        calculate_round_over_rewards(all_players)
      else
        reward = calculate_round_continue_reward(current_player)
        [reward, 0, 0, 0]
      end
    end

    private

    def calculate_round_over_rewards(players)
      players.map do |player|
        rank_reward = REWARDS_BY_RANK[player.rank]
        score_reward = player.score / NORMALIZATION_BASE_POINT
        rank_reward + score_reward
      end
    end

    def calculate_round_continue_reward(player)
      current_shanten = player.shanten_histories.last
      old_shanten = player.shanten_histories[-2]
      diff_shanten = current_shanten - old_shanten

      current_outs = player.outs_histories.last
      old_outs = player.outs_histories[-2]
      diff_outs = current_outs - old_outs

      return 2 if diff_shanten < 0
      return 2 if current_shanten == 0 # 聴牌維持の場合、報酬を1
      return 1 if diff_shanten == 0 && diff_outs > 0
      return 0 if diff_shanten == 0 && diff_outs == 0

      -1
    end
  end
end
