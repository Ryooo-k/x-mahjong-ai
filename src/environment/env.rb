# frozen_string_literal: true

require 'json'
require_relative 'state_builder'
require_relative 'reward_calculator'
require_relative '../domain/table'
require_relative '../domain/logic/hand_evaluator'
require_relative '../util/formatter'

class Env
  attr_reader :table, :current_player, :other_players

  HandEvaluator = Domain::Logic::HandEvaluator
  STARTING_HAND_COUNT = 13
  ACTION_NUMBER = 1

  def initialize(table_config, player_config)
    @table = Table.new(table_config, player_config)
    @game_over = false
    @round_over = false
    @current_player = @table.host
    @other_players = @table.children
    deal_starting_hand
    set_player_wind
    set_player_rank
  end

  def step
    current_player_draw
    states = build_states(@current_player)

    handle_tsumo_action

    discard_action, discarded_tile = handle_discard_action(states)

    ron_action, ron_player = get_ron_action(discarded_tile)
    return handle_ron_agari(states, discard_action, ron_player, ron_action, discarded_tile) if ron_player

    handle_normal_progress(states, discard_action)
  end

  def rotate_turn
    seat_orders = @table.seat_orders
    current_number = seat_orders.find_index(@current_player)
    rotated_orders = seat_orders.rotate(current_number + 1)
    @current_player = rotated_orders.first
    @other_players = rotated_orders[1..]
  end

  def sync_qnet
    @table.players.each { |player| player.sync_qnet }
  end

  def log
    Util::Formatter.build_log(@table)
  end

  def round_over?
    @round_over
  end

  def game_over?
    @game_over
  end

  def check_game_over
    result = @table.round[:count] == 8 || !@table.players.all? { |player| player.score >= 0 }
    @game_over = result
  end

  def renchan?
    @table.host.agari?
  end

  def restart
    @table.restart
    prepare_round
    set_player_rank
  end

  def proceed_to_next_round
    @table.proceed_to_next_round
    prepare_round
    set_player_wind
    set_player_rank
  end

  def reset
    @table.reset
    @game_over = false
    prepare_round
    set_player_wind
    set_player_rank
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

  def set_player_rank
    @table.ranked_players.each_with_index do |player, i|
      rank = i + 1
      player.rank = rank
    end
  end

  def current_player_draw
    top_tile = @table.top_tile
    @current_player.draw(top_tile)
    @table.increase_draw_count
  end

  def can_not_draw?
    @table.draw_count + @table.kong_count >= 122
  end

  def build_states(main_player)
    all_players = [@current_player] + @other_players
    index = all_players.find_index(main_player)
    sub_players = all_players.rotate(index + 1)[1..]
    StateBuilder.build_player_states(main_player, sub_players, @table)
  end

  def handle_tsumo_action
    states = StateBuilder.build_tsumo_states(@current_player, @other_players, @table)
    tsumo_action = @current_player.get_tsumo_action(states)

    if tsumo_action == ACTION_NUMBER
      @round_over = true
      distribute_tsumo_point
      set_player_rank
    end

    update_tsumo_agent(states, tsumo_action)
  end

  def distribute_tsumo_point
    received_point, paid_by_host, paid_by_child = HandEvaluator.calculate_tsumo_agari_point(@current_player, @table)
    @current_player.award_point(received_point)
    @other_players.each { |player| @table.host == player ? player.award_point(-paid_by_host) : player.award_point(-paid_by_child) }
  end

  def update_tsumo_agent(states, action)
    next_states = StateBuilder.build_tsumo_next_states(@current_player, @other_players, @table)
    reward = RewardCalculator.calculate_round_over_reward(@current_player)
    @current_player.update_tsumo_agent(states, action, reward, next_states, @game_over)
  end

  def handle_discard_action(states)
    discard_action = @current_player.get_discard_action(states)
    target_tile = @current_player.choose(discard_action)
    @current_player.discard(target_tile)
    @current_player.record_hand_status
    [discard_action, target_tile]
  end

  def get_ron_action(tile)
    ron_action = nil
    ron_player = nil
    round_wind = @table.round[:wind]

    @other_players.each do |player|
      if player.can_ron?(tile, round_wind)
        states = build_states(player)
        ron_action = player.get_ron_action(states)
        ron_player = player if ron_action == ACTION_NUMBER
      end
      break if !ron_player.nil?
    end
    [ron_action, ron_player]
  end

  def handle_ron_agari(current_player_states, discard_action, ron_player, ron_action, winning_tile)
    @round_over = true
    update_discard_agent(@current_player, current_player_states, discard_action)

    ron_player.draw(winning_tile)
    ron_player.record_hand_status
    ron_player_states = build_states(ron_player)
    distribute_ron_point(ron_player)
    set_player_rank

    update_ron_agent(ron_player, ron_player_states, ron_action)
  end

  def update_discard_agent(player, states, action)
    next_states = build_states(player)
    reward = RewardCalculator.calculate_round_over_reward(player)
    player.update_discard_agent(states, action, reward, next_states, @game_over)
  end

  def update_ron_agent(player, states, action)
    next_states = build_states(player)
    reward = RewardCalculator.calculate_round_over_reward(player)
    player.update_ron_agent(states, action, reward, next_states, @game_over)
  end

  def distribute_ron_point(ron_player)
    point = HandEvaluator.calculate_ron_agari_point(ron_player, @table)
    ron_player.award_point(point)
    @current_player.award_point(-point)
    @other_players.each { |player| player.award_point(0) if player != ron_player }
  end

  def handle_normal_progress(states, action)
    @round_over = can_not_draw?
    next_states = build_states(@current_player)
    reward = RewardCalculator.calculate_round_continue_reward(@current_player)
    @current_player.update_discard_agent(states, action, reward, next_states, @game_over)
  end
end
