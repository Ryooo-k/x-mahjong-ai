# frozen_string_literal: true

require 'json'
require_relative 'normal_agari_patterns'
require_relative '../tile'
require_relative '../../util/file_loader'
require_relative '../../util/encoder'

module Domain
  module Logic
    module HandEvaluator
      class << self
        ALL_TILES = Array.new(136) { |id| Tile.new(id) }.freeze
        TILE_MAP = ALL_TILES.group_by(&:code).transform_values(&:freeze).freeze
        KOKUSHI_TILE_CODES = [0, 8, 9, 17, 18, 26, 27, 28, 29, 30, 31, 32, 33].to_set.freeze
        KOKUSHI_TILES = ALL_TILES.select { |tile| KOKUSHI_TILE_CODES.include?(tile.code) }
        SHANTEN_LIST = Util::FileLoader.load_shanten_list
        CHIITOITSU_PAIR_COUNT = 7
        MAX_TILE_COUNT = 4
        MAX_SHANTEN_COUNT = 13

        def count_minimum_outs(hands)
          return 0 if hands.size == 14
          normal_outs = count_normal_outs(hands)
          chiitoitsu_outs = count_chiitoitsu_outs(hands)
          kokushi_outs = count_kokushi_outs(hands)
          [normal_outs.size, chiitoitsu_outs.size, kokushi_outs.size].min
        end

        def count_outs(hands)
          normal_outs = count_normal_outs(hands)
          chiitoitsu_outs = count_chiitoitsu_outs(hands)
          kokushi_outs = count_kokushi_outs(hands)

          {
            normal: normal_outs,
            chiitoitsu: chiitoitsu_outs,
            kokushi: kokushi_outs
          }
        end

        def calculate_minimum_shanten(hands)
          all_shanten = calculate_all_shanten(hands)
          all_shanten.min
        end

        def calculate_shanten(hands)
          all_shanten = calculate_all_shanten(hands)

          {
            normal: all_shanten[0],
            chiitoitsu: all_shanten[1],
            kokushi: all_shanten[2]
          }
        end

        def agari?(hands)
          calculate_minimum_shanten(hands) == -1
        end

        def tenpai?(hands)
          calculate_minimum_shanten(hands) == 0
        end

        def evaluate_yaku(hands:, melds_list:, winning_tile:, round_wind:, player_wind:, is_tsumo:, is_riichi:, open_dora_indicators:, blind_dora_indicators:, honba:)
          input = to_yaku_checker_format(
            hands:,
            melds_list:,
            target_tile: winning_tile,
            round_wind:,
            player_wind:,
            is_tsumo:,
            is_riichi:,
            open_dora_indicators:,
            blind_dora_indicators:,
            honba:)
          File.write("tmp/yaku_input.json", JSON.dump(input))
          result = `node src/domain/logic/yaku_checker.js`
          JSON.parse(result)
        end

        def has_yaku?(hands:, melds_list:, target_tile:, round_wind:, player_wind:, is_riichi:)
          input = to_yaku_checker_format(hands:, melds_list:, target_tile:, round_wind:, player_wind:, is_riichi:)
          File.write("tmp/yaku_input.json", JSON.dump(input))
          result = `node src/domain/logic/yaku_checker.js`
          yaku_states = JSON.parse(result)
          yaku = yaku_states["yaku"]
          yaku.empty? ? false : yaku
        end

        def calculate_tsumo_agari_point(player, table)
          input = to_yaku_checker_format(
            hands: player.hands[..-2],
            melds_list: player.melds_list,
            target_tile: player.hands.last,
            round_wind: table.round[:wind],
            player_wind: player.wind,
            is_tsumo: true,
            is_riichi: player.riichi?,
            open_dora_indicators: table.open_dora_indicators,
            blind_dora_indicators: table.blind_dora_indicators,
            honba: table.honba[:count]
            )
          File.write("tmp/yaku_input.json", JSON.dump(input))
          result = `node src/domain/logic/yaku_checker.js`
          yaku = JSON.parse(result)
          [yaku['score'], yaku['pay']['oya'], yaku['pay']['ko']]
        end

        def calculate_ron_agari_point(player, table)
          input = to_yaku_checker_format(
            hands: player.hands[..-2],
            melds_list: player.melds_list,
            target_tile: player.hands.last,
            round_wind: table.round[:wind],
            player_wind: player.wind,
            is_tsumo: true,
            is_riichi: player.riichi?,
            open_dora_indicators: table.open_dora_indicators,
            blind_dora_indicators: table.blind_dora_indicators,
            honba: table.honba[:count]
            )
          File.write("tmp/yaku_input.json", JSON.dump(input))
          result = `node src/domain/logic/yaku_checker.js`
          yaku = JSON.parse(result)
          yaku['score']
        end

        private

        def count_normal_outs(hands)
          current_shanten = calculate_minimum_shanten(hands)
          hand_ids = hands.map(&:id).to_set
          hand_codes = hands.map(&:code)
          code_counts = hand_codes.tally

          ALL_TILES.select do |tile|
            next if hand_ids.include?(tile.id)
            code = tile.code
            next if (code_counts[code] || 0) >= MAX_TILE_COUNT

            test_shanten = calculate_minimum_shanten(hands + [tile])
            test_shanten < current_shanten
          end
        end

        def count_chiitoitsu_outs(hands)
          hand_ids = hands.map(&:id).to_set
          code_counts = hands.map(&:code).tally
          single_codes = code_counts.select { |_, count| count == 1 }.keys

          single_codes.flat_map do |code|
            TILE_MAP[code].reject { |tile| hand_ids.include?(tile.id) }
          end
        end

        def count_kokushi_outs(hands)
          hand_codes = hands.map(&:code)
          hand_ids = hands.map(&:id).to_set

          used_kokushi_codes = hand_codes.select { |code| KOKUSHI_TILE_CODES.include?(code) }
          used_code_tally = used_kokushi_codes.tally
          is_head = used_code_tally.values.any? { |count| count >= 2 }

          if is_head
            unused_code_set = (KOKUSHI_TILE_CODES - used_kokushi_codes).to_set
            KOKUSHI_TILES.select { |tile| unused_code_set.include?(tile.code) }
          else
            KOKUSHI_TILES.reject { |tile| hand_ids.include?(tile.id) }
          end
        end

        def calculate_all_shanten(hands)
          normal_shanten = calculate_normal_shanten(hands)
          chiitoitsu_shanten = calculate_chiitoitsu_shanten(hands)
          kokushi_shanten = calculate_kokushi_shanten(hands)
          [normal_shanten, chiitoitsu_shanten, kokushi_shanten]
        end

        def calculate_normal_shanten(hands)
          encoded = Util::Encoder.encode_hands(hands)

          manzu_code  = encoded[0..8].to_s
          pinzu_code  = encoded[9..17].to_s
          souzu_code  = encoded[18..26].to_s
          zihai_code  = encoded[27..33].to_s

          min_distance = Float::INFINITY
          NORMAL_AGARI_PATTERNS.each do |manzu_n, pinzu_n, souzu_n, zihai_n|
            sum =
              SHANTEN_LIST['suuhai'][manzu_code][manzu_n.to_s] +
              SHANTEN_LIST['suuhai'][pinzu_code][pinzu_n.to_s] +
              SHANTEN_LIST['suuhai'][souzu_code][souzu_n.to_s] +
              SHANTEN_LIST['zihai'][zihai_code][zihai_n.to_s]
            min_distance = sum if sum < min_distance
          end
          min_distance - 1
        end

        def calculate_chiitoitsu_shanten(hands)
          code_counts = hands.map(&:code).tally
          pair_count = 0
          code_counts.each_value { |count| pair_count += 1 if count >= 2 }
          CHIITOITSU_PAIR_COUNT - pair_count - 1
        end

        def calculate_kokushi_shanten(hands)
          code_counts = hands.map(&:code).tally
          used_kokushi_codes = code_counts.select { |code, _| KOKUSHI_TILE_CODES.include?(code) }
          unique_count = used_kokushi_codes.keys.size
          has_head = used_kokushi_codes.values.any? { |count| count >= 2 }
          MAX_SHANTEN_COUNT - unique_count - (has_head ? 1 : 0)
        end

        def to_yaku_checker_format(hands:, melds_list:, target_tile:, round_wind:, player_wind:, is_tsumo: false, is_riichi: false, open_dora_indicators: [], blind_dora_indicators: [], honba: 0)
          hai = (hands + [target_tile]).map { |tile| "#{tile.number}#{tile.suit}" }
          furo = melds_list.map do |melds|
                  {
                    type: case melds[:type]
                          when 'pong' then 'pon'
                          when 'chow' then 'chi'
                          when 'concealed_kong' then 'ankan'
                          when 'open_kong' then 'daiminkan'
                          when 'extended_kong' then 'kakan'
                          else melds[:type]
                          end,
                    hai: melds[:tiles].map { |tile| "#{tile.number}#{tile.suit}" }
                  }
                end

          agari_hai = "#{target_tile.number}#{target_tile.suit}"
          dora_hyo = open_dora_indicators.map { |tile| "#{tile.number}#{tile.suit}" }
          uradora_hyo = is_riichi ? blind_dora_indicators.map { |tile| "#{tile.number}#{tile.suit}" } : []
          is_oya = player_wind == '1z' ? true : false

          {
            hai: { hai:, furo: },
            agariHai: agari_hai,
            bakaze: round_wind,
            jikaze: player_wind,
            tsumo: is_tsumo,
            doraHyo: dora_hyo,
            reach: is_riichi,
            uradoraHyo: uradora_hyo,
            honba: honba,
            oya: is_oya
          }
        end
      end
    end
  end
end
