# frozen_string_literal: true

module Util
  module Formatter
    class << self
      def build_training_log(table)
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
        info.join("\n")
      end

      def convert_number_to_kanji(num)
        num.to_s.tr('0123456789', '〇一二三四五六七八九')
      end
    end
  end
end
