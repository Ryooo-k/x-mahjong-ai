# frozen_string_literal: true

require_relative '../tile'
require_relative 'normal_agari_patterns'
require_relative '../../util/file_loader'
require_relative '../../util/encoder'

module Domain
  module Logic
    module HandEvaluator
      ALL_TILES = (0..135).map { |id| Tile.new(id) }.freeze
      KOKUSHI_TILE_CODES = [0, 8, 9, 17, 18, 26, 27, 28, 29, 30, 31, 32, 33]
      KOKUSHI_TILES = ALL_TILES.select { |tile| KOKUSHI_TILE_CODES.include?(tile.code) }
      SHANTEN_LIST = Util::FileLoader.load_shanten_list

      def self.count_minimum_outs(hands)
        normal_outs = count_normal_outs(hands)
        chiitoitsu_outs = count_chiitoitsu_outs(hands)
        kokushi_outs = count_kokushi_outs(hands)
        [normal_outs.size, chiitoitsu_outs.size, kokushi_outs.size].min
      end

      def self.count_outs(hands)
        normal_outs = count_normal_outs(hands)
        chiitoitsu_outs = count_chiitoitsu_outs(hands)
        kokushi_outs = count_kokushi_outs(hands)

        {
          normal: normal_outs,
          chiitoitsu: chiitoitsu_outs,
          kokushi: kokushi_outs
        }
      end

      def self.calculate_minimum_shanten(hands)
        all_shanten = calculate_all_shanten(hands)
        all_shanten.min
      end

      def self.calculate_shanten(hands)
        all_shanten = calculate_all_shanten(hands)

        {
          normal: all_shanten[0],
          chiitoitsu: all_shanten[1],
          kokushi: all_shanten[2]
        }
      end

      def self.agari?(hands)
        calculate_minimum_shanten(hands) == -1
      end

      def self.tenpai?(hands)
        calculate_minimum_shanten(hands) == 0
      end

      private

      def self.count_normal_outs(hands)
        current_shanten = calculate_minimum_shanten(hands)
        ALL_TILES.select do |tile|
          next if hands.map(&:id).include?(tile.id)
          test_hands = hands.dup << tile
          test_codes = test_hands.map(&:code)
          next unless test_codes.tally.all? { |_, tile_count| tile_count < 5 }
          test_shanten = calculate_minimum_shanten(test_hands)
          test_shanten < current_shanten
        end
      end

      def self.count_chiitoitsu_outs(hands)
        outs_tile_codes = hands.map(&:code).tally.select { |_, count| count == 1 }.keys
        ALL_TILES.select do |tile|
          next if hands.map(&:id).include?(tile.id)
          outs_tile_codes.include?(tile.code)
        end
      end

      def self.count_kokushi_outs(hands)
        used_kokushi_codes = hands.map(&:code).select { |tile_code| KOKUSHI_TILE_CODES.include?(tile_code) }
        unused_kokushi_codes = KOKUSHI_TILE_CODES.select { |code| !used_kokushi_codes.include?(code) }
        is_head = used_kokushi_codes.tally.values.any? { |count| count >= 2 }
        is_head ?
          KOKUSHI_TILES.select { |tile| unused_kokushi_codes.include?(tile.code) } :
          KOKUSHI_TILES.select { |tile| !hands.map(&:id).include?(tile.id) }
      end

      def self.calculate_all_shanten(hands)
        normal_shanten = calculate_normal_shanten(hands)
        chiitoitsu_shanten = calculate_chiitoitsu_shanten(hands)
        kokushi_shanten = calculate_kokushi_shanten(hands)
        [normal_shanten, chiitoitsu_shanten, kokushi_shanten]
      end

      def self.calculate_normal_shanten(hands)
        encoded_hands = Util::Encoder.encode_hands(hands)
        manzu_code = encoded_hands[0..8].to_a.map(&:to_i).to_s
        pinzu_code = encoded_hands[9..17].to_a.map(&:to_i).to_s
        souzu_code = encoded_hands[18..26].to_a.map(&:to_i).to_s
        zihai_code = encoded_hands[27..33].to_a.map(&:to_i).to_s

        min_agari_distance = NORMAL_AGARI_PATTERNS.map do |numbers|
          manzu_count = numbers[0].to_s
          pinzu_count = numbers[1].to_s
          souzu_count = numbers[2].to_s
          zihai_count = numbers[3].to_s

          manzu_agari_distance = SHANTEN_LIST['suuhai'][manzu_code][manzu_count]
          pinzu_agari_distance = SHANTEN_LIST['suuhai'][pinzu_code][pinzu_count]
          souzu_agari_distance = SHANTEN_LIST['suuhai'][souzu_code][souzu_count]
          zihai_agari_distance = SHANTEN_LIST['zihai'][zihai_code][zihai_count]
          manzu_agari_distance + pinzu_agari_distance + souzu_agari_distance + zihai_agari_distance
        end.min
        min_agari_distance - 1
      end
  
      def self.calculate_chiitoitsu_shanten(hands)
        hand_codes = hands.map(&:code)
        chiitoitsu_match_count = hand_codes.tally.values.select { |count| count >= 2 }.size
        agari_distance = 7 - chiitoitsu_match_count
        agari_distance - 1
      end
  
      def self.calculate_kokushi_shanten(hands)
        hand_codes = hands.map(&:code)
        used_kokushi_codes = hand_codes.select { |code| KOKUSHI_TILE_CODES.include?(code) }
        unused_kokushi_codes = used_kokushi_codes.uniq
        is_head = used_kokushi_codes.tally.values.any? { |count| count >= 2 }
        13 - unused_kokushi_codes.size - (is_head ? 1 : 0)
      end
    end
  end
end
