# frozen_string_literal: true

require_relative 'tile'

class TileWall
  attr_reader :tiles, :live_walls, :dead_walls, :open_dora_indicators, :blind_dora_indicators, :replacement_tiles

  def initialize(red_dora_ids = [])
    @red_dora_ids = red_dora_ids
    @tiles = build_tiles(@red_dora_ids)
    reset
  end

  def reset
    shuffled_tiles = @tiles.shuffle
    setup(shuffled_tiles)
    self
  end

  private

  def build_tiles(red_dora_ids)
    Array.new(136) do |id|
      is_red_dora = red_dora_ids.include?(id)
      Tile.new(id, is_red_dora:)
    end
  end

  def setup(tiles)
    @live_walls = tiles[0..121]
    @dead_walls = tiles[122..135]
    @open_dora_indicators = @dead_walls[0..4]
    @blind_dora_indicators = @dead_walls[5..9]
    @replacement_tiles = @dead_walls[10..13]
  end
end
