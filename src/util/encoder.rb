# frozen_string_literal: true

module Util
  module Encoder
    TILE_COUNT = 34.0
    MAX_RIVER_COUNT = 24
    MAX_OPEN_DORA_COUNT = 5

    def to_codes_count(tiles)
      counters = Array.new(TILE_COUNT, 0)
      tiles.each { |tile| counters[tile.code] += 1 }
      counters
    end

    def to_nested_codes_count(nested_tiles, outer_count)
      nested_counters = Array.new(outer_count) { Array.new(TILE_COUNT, 0) }
      nested_tiles.each_with_index do |tiles, order|
        tiles.each { |tile| nested_counters[order][tile.code] += 1 }
      end
      nested_counters
    end

    def to_normalized_river_codes(rivers)
      normalized_codes = Array.new(MAX_RIVER_COUNT, -1)
      rivers.each_with_index do |tile, order|
        normalized_codes[order] = tile.code / TILE_COUNT
      end
    end

    def to_normalized_dora_codes(dora_tiles)
      normalized_codes = Array.new(MAX_OPEN_DORA_COUNT, -1)
      dora_tiles.each_with_index do |tile, order|
        normalized_codes[order] = tile.code / TILE_COUNT
      end
    end
  end
end