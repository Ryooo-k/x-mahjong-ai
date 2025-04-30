# frozen_string_literal: true

require_relative '../domain/logic/hand_evaluator'

module Util
  module Formatter

    HandEvaluator = Domain::Logic::HandEvaluator

    class << self
      def build_training_log(table)
        log = ["ツモ回数：#{table.draw_count}\n"]

        table.seat_orders.each do |player|
          start_hands = player.hand_histories.first.sort_by(&:id)
          start_hand_shanten = HandEvaluator.calculate_minimum_shanten(start_hands)
          end_hands = player.hand_histories.last.sort_by(&:id)
          end_hand_shanten = HandEvaluator.calculate_minimum_shanten(end_hands)
          start_hand_names = start_hands.map(&:name).join(' ')
          end_hand_names = end_hands.map(&:name).join(' ')
          shanten_histories = player.shanten_histories.join(' -> ')
          outs_histories = player.outs_histories.join(' -> ')

          log << "プレイヤー#{player.id}"
          log << "配　　牌：#{start_hand_names} 、向聴数：#{start_hand_shanten}"
          log << "最終手牌：#{end_hand_names} 、向聴数：#{end_hand_shanten}"
          log << "向聴数の推移：#{shanten_histories}"
          log << "アウツの推移：#{outs_histories}"
          log << "loss：#{player.agent.total_discard_loss}"
          log << ''
        end
        log << '-' * 100
        log.join("\n")
      end

      def convert_number_to_kanji(num)
        num.to_s.tr('0123456789', '〇一二三四五六七八九')
      end
    end
  end
end
