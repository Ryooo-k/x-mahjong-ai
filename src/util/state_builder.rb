# frozen_string_literal: true

require_relative 'encoder'
require_relative '../domain/logic/hand_evaluator'

module Util
  module StateBuilder
    MAX_CALL_COUNT = 4
    ALL_SCORE = 100_000.0
    MAX_SHANTEN_COUNT = 8.0
    MAX_OUTS_COUNT = 13.0

    def self.build(current_player, other_players, table)
      current_plyer_states = build_current_player_states(current_player)
      other_players_states = build_other_players_states(other_players)
      table_states = build_table_states(table)

      states = [
        current_plyer_states,
        other_players_states,
        table_states
      ].flatten

      Torch.tensor(states, dtype: :float32)
    end

    private

    def build_current_player_states(player)
      hand_codes = Encoder.to_codes_count(player.hands)
      called_tile_codes = Encoder.to_nested_codes_count(player.called_tile_table, MAX_CALL_COUNT)
      river_codes = Encoder.to_normalized_river_codes(player.rivers)
      score = player.score / ALL_SCORE
      shanten = HandEvaluator.calculate_minimum_shanten(player.hands) / MAX_SHANTEN_COUNT
      outs = HandEvaluator.count_outs(player.hands) / MAX_OUTS_COUNT

      [
        player.id,
        hand_codes,
        called_tile_codes,
        river_codes,
        score,
        shanten,
        outs
      ]
    end

    def build_other_players_states(players)
      players.map do |player|
        called_tile_codes = Encoder.to_nested_codes_count(player.called_tile_table, MAX_CALL_COUNT)
        river_codes = Encoder.to_normalized_river_codes(player.rivers)
        score = player.score / ALL_SCORE
    
        [
          player.id,
          called_tile_codes,
          river_codes,
          score
        ]
      end
    end

    def build_table_states(table)
      remaining_tiles = table.remaining_tile_count
      open_dora_codes = Encoder.to_normalized_dora_codes(table.open_dora_tiles)
      kong_count = table.kong_count
      round = table.round[:count]
      honba = table.honba[:count]
      host_id = table.host.id
      children_ids = table.children.map { |player| player.id }

      [
        remaining_tiles,
        open_dora_codes,
        kong_count,
        round,
        honba,
        host_id,
        children_ids
      ]
    end
  end
end
