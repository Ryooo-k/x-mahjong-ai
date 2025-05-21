# frozen_string_literal: true

require_relative '../util/encoder'
require_relative '../domain/action_manager'
require_relative '../domain/logic/hand_evaluator'

module StateBuilder
  ActionManager = Domain::ActionManager
  HandEvaluator = Domain::Logic::HandEvaluator
  Encoder = Util::Encoder
  NORMALIZATION_BASE_SCORE = 100_000.0
  NORMALIZATION_BASE_POINT = 48_000.0
  MAX_SHANTEN_COUNT = 13.0
  REMAINING_TILE_COUNT = 122.0
  NORMALIZATION_BASE_ROUND = 8.0
  NORMALIZATION_BASE_HONBA = 10.0

  class << self
    def build_states_list(current_player, other_players, table)
      all_players = [current_player] + other_players
      table_states = build_table_states(table)

      all_player_states = (0..3).map do |i|
        rotated_players = all_players.rotate(i)
        main_player = rotated_players[0]
        sub_players = rotated_players[1..]

        main_player_states = build_main_player_states(main_player)
        sub_players_states = build_sub_players_states(sub_players)
        states = main_player_states + sub_players_states + table_states
        Torch.tensor(states, dtype: :float32)
      end
    end

    def build_action_mask(player, round_wind, target_tile = false)
      mask = Array.new(ActionManager.size, 0)

      ActionManager::DISCARD_RANGE.each do |i|
        mask[i] = 1 if player.hands[i]
      end

      if target_tile
        mask[ActionManager::PON_INDEX] = 1 if player.can_pon?(target_tile)
        mask[ActionManager::CHI_INDEX] = 1 if player.can_chi?(target_tile)
        mask[ActionManager::DAIMINKAN_INDEX] = 1 if player.can_daiminkan?(target_tile)
        mask[ActionManager::RON_INDEX] = 1 if player.can_ron?(target_tile, round_wind)
      end

      mask[ActionManager::ANKAN_INDEX] = 1 if player.can_ankan?
      mask[ActionManager::KAKAN_INDEX] = 1 if player.can_kakan?
      mask[ActionManager::RIICHI_INDEX] = 1 if player.can_riichi?
      mask[ActionManager::TSUMO_INDEX] = 1 if player.can_tsumo?(round_wind)
      mask[ActionManager::PASS_INDEX] = 1

      mask
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
