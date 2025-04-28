# frozen_string_literal: true

require 'json'
require_relative '../domain/table'
require_relative '../domain/logic/hand_evaluator'
require_relative '../util/state_builder'

class Env
  attr_reader :table, :current_player, :other_players

  HandEvaluator = Domain::Logic::HandEvaluator
  StateBuilder = Util::StateBuilder
  STARTING_HAND_COUNT = 13

  def initialize(table_config, player_config)
    @table = Table.new(table_config, player_config)
    deal_starting_hand
    @done = false
    @current_player = @table.host
    @other_players = @table.children
  end

  def reset
    @table.reset
    deal_starting_hand
    @done = false
  end

  def player_draw
    return if game_over?
    top_tile = @table.top_tile
    @current_player.draw(top_tile)
    @table.increase_draw_count
  end

  def states
    StateBuilder.build_states(@current_player, @other_players, @table)
  end

  def step(action)
    old_shanten = @current_player.shanten
    old_outs = @current_player.outs

    is_agari = HandEvaluator.agari?(@current_player.hands)
    target_tile = @current_player.sorted_hands[action] unless is_agari
    @current_player.discard(target_tile) unless is_agari

    new_hands = @current_player.hands
    new_shanten = HandEvaluator.calculate_minimum_shanten(new_hands)
    new_outs = HandEvaluator.count_minimum_outs(new_hands)

    @current_player.shanten = new_shanten
    @current_player.outs = new_outs

    reward = cal_reward(old_shanten, new_shanten, old_outs, new_outs, is_agari)
    @done = true if is_agari || game_over?

    [states, reward, @done, target_tile]
  end

  def rotate_turn
    seat_orders = @table.seat_orders
    current_number = seat_orders.find_index(@current_player)
    rotated_orders = seat_orders.rotate(current_number + 1)
    @current_player = rotated_orders.first
    @other_players = rotated_orders[1..]
  end

  def sync_qnet_for_all_players
    @table.players.each { |player| player.sync_qnet }
  end

  def log_training_info
    info = StateBuilder.build_log_training_info(@table)
    info.join("\n")
  end

  private

  def deal_starting_hand
    live_walls = @table.tile_wall.live_walls
    @table.wind_orders.each do |player|
      STARTING_HAND_COUNT.times do |_|
        player.draw(live_walls[@table.draw_count])
        @table.increase_draw_count
      end
      player.record_hands
      player.shanten = HandEvaluator.calculate_minimum_shanten(player.hands)
      player.outs = HandEvaluator.count_minimum_outs(player.hands)
    end
  end

  def game_over?
    @table.draw_count + @table.kong_count >= 122
  end

  def cal_reward(old_shanten, new_shanten, old_outs, new_outs, is_agari)
    return 100 if is_agari
    return -100 if game_over?

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
