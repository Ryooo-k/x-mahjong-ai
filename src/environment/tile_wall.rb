# frozen_string_literal: true

require_relative 'tile'

class TileWall
  attr_reader :live_tiles, :dead_tiles, :kong_count, :dora, :ura_dora

  MAX_KONG_COUNT = 4

  def initialize(red_dora_ids = [])
    @red_dora_ids = red_dora_ids
    @tiles = build_tiles(@red_dora_ids)
    reset
  end

  def reset
    shuffled_tiles = @tiles.shuffle
    setup_tiles(shuffled_tiles)
    @kong_count = 0
    self
  end

  def add_dora
    raise StandardError, 'カンの回数は最大4回までです。' unless can_kong?

    @kong_count += 1
    new_dora = @dora_indicator[@kong_count]
    new_ura_dora = @ura_dora_indicator[@kong_count]
    @dora << new_dora
    @ura_dora << new_ura_dora
  end

  def can_kong?
    @kong_count + 1 <= MAX_KONG_COUNT
  end

  private

  def setup_tiles(tiles)
    @live_tiles = tiles[0..121]
    @dead_tiles = tiles[122..135]
    @dora_indicator = @dead_tiles[0..4]
    @ura_dora_indicator = @dead_tiles[5..9]
    @replacement_tiles = @dead_tiles[10..13]
    @dora = [@dora_indicator.first]
    @ura_dora = [@ura_dora_indicator.first]
  end

  ## 3人麻雀用の牌山は保留
  def build_tiles(red_dora_ids)
    Array.new(136) do |id|
      red_dora = red_dora_ids.include?(id)
      code = id / 4
      Tile.new(id, code, red_dora)
    end
  end

end
