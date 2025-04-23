# frozen_string_literal: true

require 'json'
require_relative '../domain/table'
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

  def step(action)
    return nil if @done
    now_hands = @current_player.sorted_hands[:tiles]
    @done = true if win?(now_hands) || game_over?

    target = now_hands[action]
    @current_player.play(target) unless win?(now_hands)

    old_hands = @current_player.hand_histories.last
    new_hands = @current_player.sorted_hands[:tiles]
    reward = cal_reward(old_hands, new_hands)

    next_states = build_states
    [next_states, reward, @done, target]
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

  def states
    StateBuilder.build(@current_player, @other_players, @table)
  end

  def info
    shantens = cal_shantens
    sorted_hands = build_player_hand_names
    shantens.zip(sorted_hands)
  end

  def rotate_turn
    current_number = @table.seat_orders.each_index { |order| @table.seat_orders[order] == @current_player }
    rotated_orders = @table.seat_orders.rotate(current_number + 1)
    @current_player = rotated_orders.first
    @other_players = rotated_orders[1..]
  end

  def render
    # 学習結果を表示するためのメソッド
  end

  private

  def build_player_hand_names
    @table.seat_orders.map { |player| player.sorted_hands[:tiles] }
  end

  def cal_shantens
    @table.seat_orders.map do |player|
      cal_shanten(player.hands[:tiles])
    end
  end

  def game_over?
    @table.draw_count >= 122
  end

  def cal_reward(old_hands, new_hands)
    return 100 if win?
    return -100 if game_over?

    old_shanten = cal_shanten(old_hands)
    new_shanten = cal_shanten(new_hands)
    diff_shanten = new_shanten - old_shanten
    diff_outs = count_outs(new_hands) - count_outs(old_hands)

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
