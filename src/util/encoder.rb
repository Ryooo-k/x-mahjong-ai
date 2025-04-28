# frozen_string_literal: true

module Util
  module Encoder
    class << self
      TILE_COUNT = 34.0
      MAX_CALL_COUNT = 4
      MAX_RIVER_COUNT = 24
      MAX_DORA_COUNT = 5

      def encode_hands(hands)
        codes = Array.new(TILE_COUNT, 0)
        hands.each { |tile| codes[tile.code] += 1 }
        codes
      end

      def encode_called_tile_table(called_tile_table)
        code_table = Array.new(MAX_CALL_COUNT) { Array.new(TILE_COUNT, 0) }
        called_tile_table.each_with_index do |called_tiles, order|
          called_tiles.each { |tile| code_table[order][tile.code] += 1 }
        end
        code_table
      end

      def encode_rivers(rivers)
        normalized_river_codes = Array.new(MAX_RIVER_COUNT, -1)
        rivers.each_with_index do |tile, order|
          normalized_river_codes[order] = tile.code / TILE_COUNT
        end
        normalized_river_codes
      end

      def encode_dora(dora_tiles)
        normalized_dora_codes = Array.new(MAX_DORA_COUNT, -1)
        dora_tiles.each_with_index do |tile, order|
          normalized_dora_codes[order] = tile.code / TILE_COUNT
        end
        normalized_dora_codes
      end
    end
  end
end