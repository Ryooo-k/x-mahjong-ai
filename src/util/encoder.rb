# frozen_string_literal: true

module Util
  module Encoder
    class << self
      TILE_COUNT = 34.0
      MAX_CALL_COUNT = 4
      TILE_COPIES = 4
      MAX_RIVER_COUNT = 24
      MAX_DORA_COUNT = 5

      def encode_hands(hands)
        codes = Array.new(TILE_COUNT, 0)
        hands.each { |tile| codes[tile.code] += 1 }
        codes
      end

      def encode_melds_list(melds_list)
        normalized_melds_codes = Array.new(MAX_CALL_COUNT) { Array.new(TILE_COPIES, -1.0) }
        melds_list.each_with_index do |melds, list_order|
          melds.each_with_index do |tile, melds_order|
            normalized_melds_codes[list_order][melds_order] =tile.code / TILE_COUNT
          end
        end
        normalized_melds_codes.flatten
      end

      def encode_rivers(rivers)
        normalized_river_codes = Array.new(MAX_RIVER_COUNT, -1.0)
        rivers.each_with_index do |tile, order|
          normalized_river_codes[order] = tile.code / TILE_COUNT
        end
        normalized_river_codes
      end

      def encode_dora(dora_tiles)
        normalized_dora_codes = Array.new(MAX_DORA_COUNT, -1.0)
        dora_tiles.each_with_index do |tile, order|
          normalized_dora_codes[order] = tile.code / TILE_COUNT
        end
        normalized_dora_codes
      end
    end
  end
end