# frozen_string_literal: true

require 'json'

module Domain
  module Logic
    module ScoreCalculator
      class << self
        def get_yaku(hands, melds_list, winning_tile, round_wind, player_wind, is_tsumo, open_dora_indicators, is_reach, blind_dora_indicators, honba)
          input = convert_hash(hands, melds_list, winning_tile, round_wind, player_wind, is_tsumo, open_dora_indicators, is_reach, blind_dora_indicators, honba)
          File.write("tmp/yaku_input.json", JSON.dump(input))
          result = `node src/domain/logic/yaku_checker.js`
          JSON.parse(result)
        end

        private

        def convert_hash(hands, melds_list, winning_tile, round_wind, player_wind, is_tsumo, open_dora_indicators, is_reach, blind_dora_indicators, honba)
          hai = hands.map { |tile| "#{tile.number}#{tile.suit}" }
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

          agari_hai = "#{winning_tile.number}#{winning_tile.suit}"
          dora_hyo = open_dora_indicators.map { |tile| "#{tile.number}#{tile.suit}" }
          uradora_hyo = blind_dora_indicators.map { |tile| "#{tile.number}#{tile.suit}" }
          is_oya = player_wind == '1z' ? true : false

          {
            hai: { hai:, furo: },
            agariHai: agari_hai,
            bakaze: round_wind,
            jikaze: player_wind,
            tsumo: is_tsumo,
            doraHyo: dora_hyo,
            reach: is_reach,
            uradoraHyo: uradora_hyo,
            honba: honba[:count],
            oya: is_oya
          }
        end
      end
    end
  end
end
