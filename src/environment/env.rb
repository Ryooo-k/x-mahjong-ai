# frozen_string_literal: true

require 'json'
require_relative '../domain/table'
require_relative '../domain/logic/hand_evaluator'
require_relative '../util/state_builder'

class MahjongEnv
  attr_reader :current_player, :other_players

  def initialize(table_config, player_config)
    @table = Table.new(table_config, player_config)
    @done = false
    @current_player = @table.host
    @other_players = @table.children
  end

  def reset
    @table.reset
  end

  def player_draw
    top_tile = @table.top_tile
    @current_player.draw(top_tile)
    @table.increase_draw_count
  end

  def states
    Util::StateBuilder.build(@current_player, @other_players, @table)
  end

  def step(action)
    return nil if @done
    current_hands = @current_player.sorted_hands.dup
    is_agari = Domain::Logic::HandEvaluator.agari?(current_hands)
    @done = true if is_agari || game_over?

    target_tile = current_hands[action]
    @current_player.discard(target_tile) unless is_agari

    new_hands = @current_player.sorted_hands
    reward = cal_reward(current_hands, new_hands)
    [states, reward, @done, target_tile]
  end

  # def process_call_phase(target)
  #   @other_players.each do |player|
  #     next unless player.can_pong_or_open_kong?(target)

  #     call_action = player.get_call_action(states, target)
  #     if call_action == 0
  #       next
  #     elsif is_call == 1 # ポン
  #       player.pong(action)
  #     end
  #   end

  #   @other_players.first.can_call?(target)

  # end

  def info
    shantens = cal_shantens
    sorted_hands = build_player_hand_names
    shantens.zip(sorted_hands)
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

  def render
    # 学習結果を表示するためのメソッド
  end

  private

  def build_player_hand_names
    @table.seat_orders.map { |player| player.sorted_hands }
  end

  def cal_shantens
    @table.seat_orders.map do |player|
      Domain::Logic::HandEvaluator.calculate_minimum_shanten(player.hands)
    end
  end

  def game_over?
    @table.draw_count >= 122
  end

  def cal_reward(old_hands, new_hands)
    return 100 if Domain::Logic::HandEvaluator.agari?(new_hands)
    return -100 if game_over?

    old_shanten = Domain::Logic::HandEvaluator.calculate_minimum_shanten(old_hands)
    new_shanten = Domain::Logic::HandEvaluator.calculate_minimum_shanten(new_hands)
    diff_shanten = new_shanten - old_shanten
    diff_outs = Domain::Logic::HandEvaluator.count_minimum_outs(new_hands) - Domain::Logic::HandEvaluator.count_minimum_outs(old_hands)

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
