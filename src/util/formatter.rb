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

      def build_tenpai_speed_log(table)
        rows = []

        table.players.each do |player|
          shanten_history = format_histories(player.shanten_histories)
          outs_history = format_histories(player.outs_histories)
          hand_status_history = "向聴数：#{shanten_history}\nアウツ：#{outs_history}"
          start_hand = format_hand(player.hand_histories.first)
          end_hand = format_hand(player.hand_histories.last)
          hand_history = "配　　牌：#{start_hand}\n最終手配：#{end_hand}"

          rows << [
            "Player#{player.id}",
            player.tenpai_count,
            player.loss.to_i,
            hand_status_history,
            hand_history
          ]

          rows << []
        end
        rows.pop

        Terminal::Table.new(
          headings: ['プレイヤー', '聴牌数', 'loss', '推移', '手牌'],
          rows: rows
        )
      end

      def convert_number_to_kanji(num)
        num.to_s.tr('0123456789', '〇一二三四五六七八九')
      end

      private

      def format_hand(hands)
        hands.sort_by(&:id).map { |tile| tile.name.rjust(2) }.join(' ')
      end

      def format_histories(histories)
        histories.map { |history| history.to_s.rjust(2) }.join('->')
      end
    end
  end
end
