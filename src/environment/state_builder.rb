# frozen_string_literal: true

require_relative '../util/encoder'
require_relative '../domain/logic/hand_evaluator'

module StateBuilder
  HandEvaluator = Domain::Logic::HandEvaluator
  Encoder = Util::Encoder
  ALL_SCORE = 100_000.0
  MAX_SHANTEN_COUNT = 13.0
  REMAINING_TILE_COUNT = 122.0
  ROUND_COUNT = 8.0
  NORMALIZATION_BASE = 10.0


  class << self
    def build_all_player_states(current_player, other_players, table)
      all_players = [current_player] + other_players
      all_players.each_with_index.map do |player, i|
        rotated_players = all_players.rotate(i)
        main_player = rotated_players.first
        sub_players = rotated_players[1..]
        build_states(main_player, sub_players, table)
      end
    end

    private

    def build_states(main_player, sub_players, table)
      main_player_states = build_main_player_states(main_player)
      sub_players_states = build_sub_players_states(sub_players)
      table_states = build_table_states(table)
      states = main_player_states + sub_players_states + table_states
      Torch.tensor(states, dtype: :float32)
    end

    def build_main_player_states(player)
      hand_codes = Encoder.encode_hands(player.hands)
      melds_codes = Encoder.encode_melds_list(player.melds_list)
      river_codes = Encoder.encode_rivers(player.rivers)
      reach = player.reach? ? 1 : 0
      menzen = player.menzen? ? 1 : 0
      score = player.score / ALL_SCORE
      shanten = HandEvaluator.calculate_minimum_shanten(player.hand_histories.last)
      outs = HandEvaluator.count_minimum_outs(player.hand_histories.last) / NORMALIZATION_BASE

      [
        *hand_codes,
        *melds_codes,
        *river_codes,
        reach,
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
        reach = player.reach? ? 1 : 0
        menzen = player.menzen? ? 1 : 0
        score = player.score / ALL_SCORE

        [
          *melds_codes,
          *river_codes,
          reach,
          menzen,
          score
        ]
      end
    end

    def build_table_states(table)
      remaining_tile_count = table.remaining_tile_count / REMAINING_TILE_COUNT
      open_dora_codes = Encoder.encode_doras(table.open_dora_codes)
      kong_count = table.kong_count
      round_count = table.round[:count] / ROUND_COUNT
      honba_count = table.honba[:count] / NORMALIZATION_BASE

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
