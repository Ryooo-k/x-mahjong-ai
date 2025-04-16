# frozen_string_literal: true

require_relative 'tile_wall'
require_relative 'player'

## 3人麻雀の実装は保留
class Table
  attr_reader :game_mode, :attendance, :red_dora, :tile_wall, :players, :seat_orders, :draw_count

  GAME_MODES = {
  0 => { name: '東風戦', end_round: 4 },
  1 => { name: '東南戦', end_round: 8 }
  }.freeze

  RED_DORA_MODES = {
    0 => { ids: [], name: [] },
    1 => { ids: [19, 55, 91], name: ['5萬', '5筒', '5索'] }
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

  STARTING_HAND_COUNT = 13

  def initialize(table_config, player_config)
    @game_mode = GAME_MODES[table_config['game_mode_id']]
    @attendance = table_config['attendance']
    @red_dora = RED_DORA_MODES[table_config['red_dora_mode_id']]
    @tile_wall = TileWall.new(@red_dora[:ids])
    @players = Array.new(attendance) { |id| Player.new(id, player_config['discard_agent'], player_config['call_agent']) }
    reset_game_state
  end

  def reset
    @tile_wall.reset
    @players.each(&:reset)
    reset_game_state
    deal_starting_hand
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

  def restart_round_count
    @round_count = 0
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

  def deal_starting_hand
    wind_orders.each do |player|
      STARTING_HAND_COUNT.times do |_|
        player.draw(@tile_wall.live_walls[@draw_count])
        increase_draw_count
      end
      player.record_hands
    end
  end

  private

  def reset_game_state
    @seat_orders = @players.shuffle
    @draw_count = 0
    restart_round_count
    restart_honba_count
  end

  def convert_number_to_kanji(num)
    num.to_s.tr('0123456789', '〇一二三四五六七八九')
  end
end
