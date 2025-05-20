# frozen_string_literal: true

require_relative '../util/encoder'
require_relative '../domain/logic/hand_evaluator'

module StateBuilder
  HandEvaluator = Domain::Logic::HandEvaluator
  Encoder = Util::Encoder
  NORMALIZATION_BASE_SCORE = 100_000.0
  NORMALIZATION_BASE_POINT = 48_000.0
  MAX_SHANTEN_COUNT = 13.0
  REMAINING_TILE_COUNT = 122.0
  NORMALIZATION_BASE_ROUND = 8.0
  NORMALIZATION_BASE_HONBA = 10.0

  class << self
    def build_discard_states(current_player, other_players, table)
      current_player_states = build_main_player_states(current_player)
      other_players_states = build_sub_players_states(other_players)
      table_states = build_table_states(table)
      states = current_player_states + other_players_states + table_states
      Torch.tensor(states, dtype: :float32)
    end

    def build_tsumo_states(current_player, other_players, table)
      is_tsumo = current_player.can_tsumo? ? 1.0 : 0.0

      received_point, *_ = HandEvaluator.calculate_tsumo_agari_point(current_player, table)
      normalized_point = received_point / NORMALIZATION_BASE_POINT

      scores = ([current_player] + other_players).map(&:score)
      normalized_scores = scores.map { |score| score / NORMALIZATION_BASE_SCORE }

      normalized_round = table.round[:count] / NORMALIZATION_BASE_ROUND

      states = [
        is_tsumo,
        normalized_point,
        *normalized_scores,
        normalized_round
      ]

      Torch.tensor(states, dtype: :float32)
    end

    def build_tsumo_next_states(current_player, other_players, table)
      is_tsumo = 0.0
      point = 0.0
      scores = ([current_player] + other_players).map(&:score)
      normalized_scores = scores.map { |score| score / NORMALIZATION_BASE_SCORE }
      normalized_round = (table.round[:count] + 1) / NORMALIZATION_BASE_ROUND

      states = [
        is_tsumo,
        point,
        *normalized_scores,
        normalized_round
      ]

      Torch.tensor(states, dtype: :float32)
    end

    private

    def build_main_player_states(player)
      hand_codes = Encoder.encode_hands(player.hands)
      melds_codes = Encoder.encode_melds_list(player.melds_list)
      river_codes = Encoder.encode_rivers(player.rivers)
      riichi = player.riichi? ? 1 : 0
      menzen = player.menzen? ? 1 : 0
      score = player.score / NORMALIZATION_BASE_SCORE
      shanten = HandEvaluator.calculate_minimum_shanten(player.hand_histories.last)
      outs = HandEvaluator.count_minimum_outs(player.hand_histories.last) / NORMALIZATION_BASE_HONBA

      [
        *hand_codes,
        *melds_codes,
        *river_codes,
        riichi,
        menzen,
        score,
        shanten,
        outs
      ]
    end

    def build_sub_players_states(players)
      players.flat_map do |player|
        melds_codes = Encoder.encode_melds_list(player.melds_list)
        river_codes = Encoder.encode_rivers(player.rivers)
        riichi = player.riichi? ? 1 : 0
        menzen = player.menzen? ? 1 : 0
        score = player.score / NORMALIZATION_BASE_SCORE

        [
          *melds_codes,
          *river_codes,
          riichi,
          menzen,
          score
        ]
      end
    end

    def build_table_states(table)
      remaining_tile_count = table.remaining_tile_count / REMAINING_TILE_COUNT
      open_dora_codes = Encoder.encode_doras(table.open_dora_codes)
      kong_count = table.kong_count
      round_count = table.round[:count] / NORMALIZATION_BASE_ROUND
      honba_count = table.honba[:count] / NORMALIZATION_BASE_HONBA

      [
        *remaining_tile_count,
        *open_dora_codes,
        kong_count,
        round_count,
        honba_count
      ]
    end
  end
end
