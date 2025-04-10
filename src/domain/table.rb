# frozen_string_literal: true

require_relative 'tile_wall'
require_relative 'player'

## 3人麻雀の実装は保留
class Table
  attr_reader :game_mode, :attendance, :red_dora, :tile_wall, :players, :seat_order, :host

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

  def initialize(game_mode_id = 1, attendance = 4, red_dora_mode_id = 1)
    @game_mode = GAME_MODES[game_mode_id]
    @attendance = attendance
    @red_dora = RED_DORA_MODES[red_dora_mode_id]
    @tile_wall = TileWall.new(@red_dora[:ids])
    @players = Array.new(attendance) { |id| Player.new(id) }
    @seat_order = @players.shuffle
    @host = determine_host
    @round_count = 0
    @honba_count = 0
  end

  def reset
    @tile_wall.reset
    @players.each { |player| player.reset }
    @seat_order = @players.shuffle
    @host = determine_host
    restart_round_count
    restart_honba_count
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

  def restart_round_count
    @round_count = 0
  end

  def restart_honba_count
    @honba_count = 0
  end

  def player_order
    @seat_order.rotate(@host[:seat_number])
  end

  def deal_starting_hand
    count = 0

    player_order.each do |player|
      STARTING_HAND_COUNT.times do |_|
        player.draw(@tile_wall.live_walls[count])
        count += 1
      end
    end
  end

  private

  def determine_host
    player, seat_number = @seat_order.each_with_index.to_a.sample
    { player:, seat_number: }
  end

  def convert_number_to_kanji(num)
    num.to_s.tr('0123456789', '〇一二三四五六七八九')
  end
end
