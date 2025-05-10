# frozen_string_literal: true

require 'json'
require_relative 'state_builder'
require_relative 'reward_calculator'
require_relative '../domain/table'
require_relative '../util/formatter'

class Env
  attr_reader :table, :current_player, :other_players
  attr_accessor :game_over, :round_over

  Formatter = Util::Formatter
  STARTING_HAND_COUNT = 13
  RON_ACTION = 0

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
    return handle_tsumo_agari if @current_player.agari?

    target_tile = @current_player.choose(discard_action)
    @current_player.discard(target_tile)
    @current_player.record_hand_status

    ron_action, ron_player = get_ron_action(target_tile)
    return handle_ron_agari(ron_player, target_tile, ron_action) if ron_player

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
    ron_player = nil
    round_wind = @table.round[:wind]

    @other_players.each do |player|
      if player.can_ron?(tile, round_wind)
        ron_action = player.get_ron_action(ron_states)
        ron_player = player if ron_action == RON_ACTION
      end
      break if !ron_player.nil?
    end
    [ron_action, ron_player]
  end

  def handle_tsumo_agari
    received_point, paid_by_host, paid_by_child = HandEvaluator.calculate_tsumo_agari_point(@current_player, @table)
    @current_player.award_point(received_point)
    @other_players.each { |player| player.host? ? player.award_point(paid_by_host) : player.award_point(paid_by_child) }
    @round_over = true
    states = StateBuilder.build_all_player_states(@current_player, @other_players, @table)
    rewards = RewardCalculator.calculate_round_over_rewards(@current_player, @other_players)
    [states, rewards, @game_over]
  end

  def handle_ron_agari(ron_player, winning_tile, ron_action)
    ron_player.draw(winning_tile)
    point = HandEvaluator.calculate_ron_agari_point(ron_player, @table)
    ron_player.award_point(point)
    @current_player.award_point(-point)
    @other_players.each { |player| player.award_point(0) if player != ron_player }
    @round_over = true
    states = StateBuilder.build_all_player_states(@current_player, @other_players, @table)
    rewards = RewardCalculator.calculate_round_over_rewards(@current_player, @other_players)
    ron_player.update_ron_agent(ron_state, ron_action, reward, ron_next_state, @game_over)
    [states, rewards, @game_over]
  end

  def handle_normal_progress
    @round_over = round_over?
    states = StateBuilder.build_all_player_states(@current_player, @other_players, @table)
    rewards = RewardCalculator.calculate_round_continue_rewards(@current_player, @other_players)
    [states, rewards, @game_over]
  end
end
