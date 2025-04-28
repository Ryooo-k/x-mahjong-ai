# frozen_string_literal: true

require_relative 'encoder'
require_relative '../domain/logic/hand_evaluator'

module Util
  module StateBuilder
    class << self
      HandEvaluator = Domain::Logic::HandEvaluator
      Encoder = Util::Encoder
      ALL_SCORE = 100_000.0
      MAX_SHANTEN_COUNT = 13.0
      MAX_OUTS_COUNT = 13.0

      def build_states(current_player, other_players, table)
        current_plyer_states = build_current_player_states(current_player)
        other_players_states = build_other_players_states(other_players)
        table_states = build_table_states(table)
        states = current_plyer_states + other_players_states + table_states
        Torch.tensor(states, dtype: :float32)
      end

      def build_log_training_info(table)
        info = ["ツモ回数：#{table.draw_count}"]
        table.players.each do |player|
          start_hands = player.hand_histories.first.sort_by(&:id)
          start_hand_shanten = HandEvaluator.calculate_minimum_shanten(start_hands)
          end_hands = player.hand_histories.last.sort_by(&:id)
          end_hand_shanten = HandEvaluator.calculate_minimum_shanten(end_hands)
          start_hand_names = start_hands.map(&:name).join(' ')
          end_hand_names = end_hands.map(&:name).join(' ')

          info << "プレイヤー#{player.id}"
          info << "配　　牌：#{start_hand_names} 、向聴数：#{start_hand_shanten}"
          info << "最終手牌：#{end_hand_names} 、向聴数：#{end_hand_shanten}"
          info << ''
        end
        info << '-' * 50
      end

      private

      def build_current_player_states(player)
        hand_codes = Encoder.encode_hands(player.hands)
        called_tile_codes = Encoder.encode_called_tile_table(player.called_tile_table).flatten
        river_codes = Encoder.encode_rivers(player.rivers)
        score = player.score / ALL_SCORE
        shanten = HandEvaluator.calculate_minimum_shanten(player.hands)
        outs = HandEvaluator.count_minimum_outs(player.hands)

        [
          *hand_codes,
          *called_tile_codes,
          *river_codes,
          score,
          shanten,
          outs
        ]
      end

      def build_other_players_states(players)
        players.flat_map do |player|
          called_tile_codes = Encoder.encode_called_tile_table(player.called_tile_table).flatten
          river_codes = Encoder.encode_rivers(player.rivers)
          score = player.score / ALL_SCORE

          [
            *called_tile_codes,
            *river_codes,
            score
          ]
        end
      end

      def build_table_states(table)
        remaining_tiles = table.remaining_tile_count
        open_dora_codes = Encoder.encode_dora(table.open_dora_tiles)
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
end
