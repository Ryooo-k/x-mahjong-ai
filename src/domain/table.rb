# frozen_string_literal: true

require_relative 'tile_wall'
require_relative 'player'

class Table
  attr_reader :game_mode, :attendance, :red_dora, :tile_wall, :players, :seat_orders, :draw_count, :kong_count

  GAME_MODES = {
  0 => { name: '東風戦', end_round: 4 },
  1 => { name: '東南戦', end_round: 8 }
  }.freeze

  RED_DORA_MODES = {
    0 => { ids: [], names: [] },
    1 => { ids: [19, 55, 91], names: ['5萬', '5筒', '5索'] }
  }.freeze

  ROUNDS = { 
    0 => '東一局',
    1 => '東二局',
    2 => '東三局',
    3 => '東四局',
    4 => '南一局',
    5 => '南二局',
    6 => '南三局',
    7 => '南四局'
  }.freeze

  SPECIAL_DORA_RULES = {
    8 => 0, # 9萬がドラ表示牌の時、1萬がドラとなるcode変換
    17 => 9, # 9筒がドラ表示牌の時、1筒がドラとなるcode変換
    26 => 18, # 9索がドラ表示牌の時、1索がドラとなるcode変換
    30 => 27, # 北がドラ表示牌の時、東がドラとなるcode変換
    33 => 31 # 中がドラ表示牌の時、白がドラとなるcode変換
  }.freeze

  def initialize(table_config, player_config)
    @game_mode = GAME_MODES[table_config['game_mode_id']]
    @attendance = table_config['attendance']
    @red_dora = RED_DORA_MODES[table_config['red_dora_mode_id']]
    @tile_wall = TileWall.new
    @players = Array.new(attendance) { |id| Player.new(id, player_config['discard_agent'], player_config['call_agent']) }
    reset_game_state
  end

  def reset
    @tile_wall.reset
    @players.each(&:reset)
    reset_game_state
    self
  end

  def round
    name = ROUNDS[@round_count]
    { count: @round_count, name: }
  end

  def honba
    number_kanji = convert_number_to_kanji(@honba_count)
    name = "#{number_kanji}本場"
    { count: @honba_count, name: }
  end

  def advance_round
    @round_count += 1
  end

  def increase_honba
    @honba_count += 1
  end

  def increase_draw_count
    @draw_count += 1
  end

  def increase_kong_count
    @kong_count += 1
  end

  def restart_honba_count
    @honba_count = 0
  end

  def wind_orders
    host_number = @round_count % 4
    @seat_orders.rotate(host_number)
  end

  def host
    wind_orders.first
  end

  def children
    wind_orders[1..]
  end

  def top_tile
    @tile_wall.live_walls[@draw_count]
  end

  def remaining_tile_count
    @tile_wall.live_walls[@draw_count..].size
  end

  def open_dora_tiles
    open_dora_indicators = @tile_wall.open_dora_indicators[0..@kong_count]
    fetch_dora_tiles(open_dora_indicators)
  end

  def blind_dora_tiles
    blind_dora_indicators = @tile_wall.blind_dora_indicators[0..@kong_count]
    fetch_dora_tiles(blind_dora_indicators)
  end

  private

  def reset_game_state
    @seat_orders = @players.shuffle
    @draw_count = 0
    @kong_count = 0
    @round_count = 0
    restart_honba_count
  end

  def fetch_dora_tiles(indicators)
    indicators = indicators[0..@kong_count]
    indicators.map do |indicator|
      dora_code = SPECIAL_DORA_RULES.fetch(indicator.code, indicator.code + 1)
      @tile_wall.tiles.select { |tile| tile.code == dora_code }
    end.flatten
  end

  def convert_number_to_kanji(num)
    num.to_s.tr('0123456789', '〇一二三四五六七八九')
  end
end
