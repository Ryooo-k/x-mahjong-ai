# frozen_string_literal: true

require_relative 'tile_wall'
require_relative 'tenpai_speed_player'
require_relative '../util/formatter'

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
    0 => { name: '東一局', code: '1z' },
    1 => { name: '東二局', code: '1z' },
    2 => { name: '東三局', code: '1z' },
    3 => { name: '東四局', code: '1z' },
    4 => { name: '南一局', code: '2z' },
    5 => { name: '南二局', code: '2z' },
    6 => { name: '南三局', code: '2z' },
    7 => { name: '南四局', code: '2z' },
    8 => { name: '西一局', code: '3z' },
    9 => { name: '西二局', code: '3z' },
    10 => { name: '西三局', code: '3z' },
    11 => { name: '西四局', code: '3z' }
  }.freeze

  SPECIAL_DORA_RULES = {
    8 => 0, # 9萬がドラ表示牌の時、1萬がドラとなるcode変換
    17 => 9, # 9筒がドラ表示牌の時、1筒がドラとなるcode変換
    26 => 18, # 9索がドラ表示牌の時、1索がドラとなるcode変換
    30 => 27, # 北がドラ表示牌の時、東がドラとなるcode変換
    33 => 31 # 中がドラ表示牌の時、白がドラとなるcode変換
  }.freeze

  def initialize(table_config, agent_config)
    @game_mode = GAME_MODES[table_config['game_mode_id']]
    @attendance = table_config['attendance']
    @red_dora = RED_DORA_MODES[table_config['red_dora_mode_id']]
    @tile_wall = TileWall.new
    @players = Array.new(attendance) { |id| Player.new(id, agent_config) }
    @seat_orders = @players.shuffle
    @draw_count = 0
    @kong_count = 0
    @round_count = 0
    @honba_count = 0
  end

  def round
    name = ROUNDS[@round_count][:name]
    wind = ROUNDS[@round_count][:code]
    { count: @round_count, name:, wind: }
  end

  def honba
    number_kanji = Util::Formatter.convert_number_to_kanji(@honba_count)
    name = "#{number_kanji}本場"
    { count: @honba_count, name: }
  end

  def increase_draw_count
    @draw_count += 1
  end

  def increase_kong_count
    @kong_count += 1
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

  def open_dora_indicators
    @tile_wall.open_dora_indicators[..@kong_count]
  end

  def blind_dora_indicators
    @tile_wall.blind_dora_indicators[..@kong_count]
  end

  def open_dora_codes
    fetch_dora_codes(open_dora_indicators)
  end

  def blind_dora_codes
    fetch_dora_codes(blind_dora_indicators)
  end

  def ranked_players
    @seat_orders.reverse.sort_by(&:score).reverse
  end

  def restart
    prepare_table
    @honba_count += 1
  end

  def proceed_to_next_round
    prepare_table
    @round_count += 1
    @honba_count = 0
  end

  def reset
    prepare_table
    @round_count = 0
    @honba_count = 0
    @players.each(&:reset)
    @seat_orders = @players.shuffle
  end

  private

  def prepare_table
    @tile_wall.reset
    @players.each(&:restart)
    @draw_count = 0
    @kong_count = 0
  end

  def fetch_dora_codes(indicators)
    indicators.map { |indicator| SPECIAL_DORA_RULES.fetch(indicator.code, indicator.code + 1) }
  end
end
