# frozen_string_literal: true

require 'json'
require_relative 'state_builder'
require_relative '../domain/table'
require_relative '../util/formatter'

class Env
  attr_reader :table, :current_player, :other_players
  attr_accessor :game_over, :round_over

  Formatter = Util::Formatter
  STARTING_HAND_COUNT = 13

  def initialize(table_config, player_config)
    @table = Table.new(table_config, player_config)
    @game_over = false
    @round_over = false
    @current_player = @table.host
    @other_players = @table.children
    deal_starting_hand
    set_player_wind
  end

  def player_draw
    top_tile = @table.top_tile
    @current_player.draw(top_tile)
    @table.increase_draw_count
  end

  def states
    StateBuilder.build_states(@current_player, @other_players, @table)
  end

  def step(discard_action)
    return handle_agari if @current_player.agari?

    target_tile = @current_player.choose(discard_action)
    @current_player.discard(target_tile)
    @current_player.record_hand_status

    ron_action = get_ron_action(target_tile)
    return handle_ron(target_tile) if ron_action

    handle_normal_progress(target_tile)
  end

  def rotate_turn
    seat_orders = @table.seat_orders
    current_number = seat_orders.find_index(@current_player)
    rotated_orders = seat_orders.rotate(current_number + 1)
    @current_player = rotated_orders.first
    @other_players = rotated_orders[1..]
  end

  def update_agent
  end

  def sync_qnet_for_all_players
    @table.players.each { |player| player.sync_qnet }
  end

  def log
    Formatter.build_training_log(@table)
  end

  def renchan?
    @table.host.agari?
  end

  def restart
    @table.restart
    prepare_round
  end

  def proceed_to_next_round
    @table.proceed_to_next_round
    prepare_round
    set_player_wind
  end

  def reset
    @table.reset
    @game_over = false
    prepare_round
    set_player_wind
  end

  private

  def deal_starting_hand
    live_walls = @table.tile_wall.live_walls
    @table.wind_orders.each do |player|
      STARTING_HAND_COUNT.times do |_|
        player.draw(live_walls[@table.draw_count])
        @table.increase_draw_count
      end
      player.record_hand_status
    end
  end

  def prepare_round
    @round_over = false
    @current_player = @table.host
    @other_players = @table.children
    deal_starting_hand
  end

  def set_player_wind
    @table.wind_orders.each_with_index { |player, i| player.wind = "#{i + 1}z" }
  end

  def round_over?
    @table.draw_count + @table.kong_count >= 122
  end

  def get_ron_action(tile)
    ron_action = nil
    round_wind = @table.round[:wind]

    @other_players.each_with_index do |player, order|
      ron_action = player.get_ron_action(states) if player.can_ron?(tile, round_wind)
      break if !ron_action.nil?
    end
    ron_action
  end

  def handle_agari
    reward = 100
    @round_over = true
    target_tile = nil
    [states, reward, @round_over, target_tile]
  end

  def handle_ron(target_tile)
    reward = 100
    @round_over = true
    target_tile = nil
    [states, reward, @round_over, target_tile]
  end

  def handle_normal_progress(target_tile)
    old_shanten, old_outs = get_previous_status
    new_shanten, new_outs = get_current_status
    reward = cal_reward(old_shanten, new_shanten, old_outs, new_outs, false)
    @round_over = round_over?
    [states, reward, @round_over, target_tile]
  end

  def cal_reward(old_shanten, new_shanten, old_outs, new_outs, is_agari)
    return 100 if is_agari
    return -100 if round_over?

    diff_shanten = new_shanten - old_shanten
    diff_outs = new_outs - old_outs

    return 50 if diff_shanten < 0
    return 50 if new_shanten == 0 && diff_outs > 0
    return 30 if new_shanten == 0 && diff_outs == 0
    return -10 if new_shanten == 0 && diff_outs < 0
    return 10 if diff_shanten == 0 && diff_outs > 0
    return -10 if diff_shanten == 0 && diff_outs == 0
    return -30 if diff_shanten == 0 && diff_outs < 0

    -50
  end
end
