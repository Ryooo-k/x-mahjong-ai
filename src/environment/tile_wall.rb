# frozen_string_literal: true

require_relative 'tile'

class TileWall
  attr_reader :tiles, :live_walls, :dead_walls, :kong_count, :open_dora_indicators, :blind_dora_indicators, :replacement_tiles, :open_dora_codes, :blind_dora_codes

  MAX_KONG_COUNT = 4

  SPECIAL_DORA_RULES = {
  8 => 0, # 9萬がドラ表示牌の時、1萬がドラとなる
  17 => 9, # 9筒がドラ表示牌の時、1筒がドラとなる
  26 => 18, # 9索がドラ表示牌の時、1索がドラとなる
  30 => 27, # 北がドラ表示牌の時、東がドラとなる
  33 => 31 # 中がドラ表示牌の時、白がドラとなる
  }.freeze

  def initialize(red_dora_ids = [])
    @red_dora_ids = red_dora_ids
    @tiles = build_tiles(@red_dora_ids)
    reset
  end

  def reset
    @kong_count = 0
    @open_dora_codes = []
    @blind_dora_codes = []
    shuffled_tiles = @tiles.shuffle
    setup(shuffled_tiles)
    update_dora
    self
  end

  def add_dora
    raise StandardError, 'カンの回数は最大4回までです。' unless can_kong?

    @kong_count += 1
    update_dora
  end

  def can_kong?
    @kong_count + 1 <= MAX_KONG_COUNT
  end

  private

  def setup(tiles)
    @live_walls = tiles[0..121]
    @dead_walls = tiles[122..135]
    @open_dora_indicators = @dead_walls[0..4]
    @blind_dora_indicators = @dead_walls[5..9]
    @replacement_tiles = @dead_walls[10..13]
  end

  ## 3人麻雀用の牌山は保留
  def build_tiles(red_dora_ids)
    Array.new(136) do |id|
      is_red_dora = red_dora_ids.include?(id)
      code = id / 4
      Tile.new(id, code, is_red_dora)
    end
  end

  def update_dora
    new_open_dora_indicator_code = @open_dora_indicators[@kong_count].code
    new_blind_dora_indicator_code = @blind_dora_indicators[@kong_count].code
    add_dora_code(new_open_dora_indicator_code, @open_dora_codes)
    add_dora_code(new_blind_dora_indicator_code, @blind_dora_codes)
    increase_dora_count
  end

  def add_dora_code(indicator_code, dora_codes)
    new_dora_code = SPECIAL_DORA_RULES.fetch(indicator_code, indicator_code + 1)
    dora_codes << new_dora_code
  end

  def increase_dora_count
    new_open_dora_code = @open_dora_codes.last
    new_blind_dora_code = @blind_dora_codes.last
    target_open_dora_tiles = @tiles.select { |tile| tile.code == new_open_dora_code }
    target_blind_dora_tiles = @tiles.select { |tile| tile.code == new_blind_dora_code }
    target_open_dora_tiles.each { |tile| tile.increase_open_dora_count }
    target_blind_dora_tiles.each { |tile| tile.increase_blind_dora_count }
  end
end
