# frozen_string_literal: true

require 'terminal-table'
require_relative '../domain/logic/hand_evaluator'

module Util
  module Formatter
    HandEvaluator = Domain::Logic::HandEvaluator

    class << self
      def build_log(table)
        rows = []

        table.players.each do |player|
          start_hand = player.hand_histories.first.sort_by(&:id).map(&:name).join(' ')
          end_hand = player.hand_histories.last.sort_by(&:id).map(&:name).join(' ')
          hand_history = "配　　牌：#{start_hand}\n最終手配：#{end_hand}"

          rows << [
            "Player#{player.id}",
            player.rank,
            player.score,
            player.shanten_histories.join('->'),
            hand_history
          ]
      
          rows << []
        end
        rows.pop

        Terminal::Table.new(
          title: table.round[:name],
          headings: ['プレイヤー', '順位', '持ち点', '向聴数の推移', '手配'],
          rows: rows
        )
      end

      def convert_number_to_kanji(num)
        num.to_s.tr('0123456789', '〇一二三四五六七八九')
      end
    end
  end
end
