# frozen_string_literal: true

require_relative 'encoder'
require_relative '../domain/logic/hand_evaluator'

module Util
  module StateBuilder
    ALL_SCORE = 100_000.0
    MAX_SHANTEN_COUNT = 13.0
    MAX_OUTS_COUNT = 13.0

    def self.build_states(current_player, other_players, table)
      current_plyer_states = build_current_player_states(current_player)
      other_players_states = build_other_players_states(other_players)
      table_states = build_table_states(table)
      states = current_plyer_states + other_players_states + table_states
      Torch.tensor(states, dtype: :float32)
    end

    def self.build_log_training_info(table)
      info = ["ツモ回数：#{table.draw_count}"]
      table.players.each do |player|
        start_hand = player.hand_histories.first
        start_hand_shanten = Domain::Logic::HandEvaluator.calculate_minimum_shanten(start_hand)
        end_hand = player.hand_histories.last
        end_hand_shanten = Domain::Logic::HandEvaluator.calculate_minimum_shanten(end_hand)

        info << "プレイヤー#{player.id}"
        info << "配　　牌：#{start_hand.map(&:name).sort.join(' ')} 、向聴数：#{start_hand_shanten}"
        info << "最終手牌：#{end_hand.map(&:name).sort.join(' ')} 、向聴数：#{end_hand_shanten}"
        info << ''
      end
      info << '-' * 50
    end

    private

    def self.build_current_player_states(player)
      hand_codes = Util::Encoder.encode_hands(player.hands)
      called_tile_codes = Util::Encoder.encode_called_tile_table(player.called_tile_table).flatten
      river_codes = Util::Encoder.encode_rivers(player.rivers)
      score = player.score / ALL_SCORE
      shanten = Domain::Logic::HandEvaluator.calculate_minimum_shanten(player.hands)
      outs = Domain::Logic::HandEvaluator.count_minimum_outs(player.hands)

      [
        *hand_codes,
        *called_tile_codes,
        *river_codes,
        score,
        shanten,
        outs
      ]
    end

    def self.build_other_players_states(players)
      players.flat_map do |player|
        called_tile_codes = Util::Encoder.encode_called_tile_table(player.called_tile_table).flatten
        river_codes = Util::Encoder.encode_rivers(player.rivers)
        score = player.score / ALL_SCORE

        [
          *called_tile_codes,
          *river_codes,
          score
        ]
      end
    end

    def self.build_table_states(table)
      remaining_tiles = table.remaining_tile_count
      open_dora_codes = Util::Encoder.encode_dora(table.open_dora_tiles)
      kong_count = table.kong_count
      round = table.round[:count]
      honba = table.honba[:count]
      host_id = table.host.id
      children_ids = table.children.map { |player| player.id }

      [
        *remaining_tiles,
        *open_dora_codes,
        kong_count,
        round,
        honba,
        host_id,
        *children_ids
      ]
    end
  end
end
