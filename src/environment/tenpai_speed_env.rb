# frozen_string_literal: true

require_relative 'state_builder'
require_relative 'reward_calculator'
require_relative '../domain/tenpai_speed_table'
require_relative '../util/formatter'

class Env
  attr_reader :table, :current_player, :other_players

  STARTING_HAND_COUNT = 13
  ACTION_DONE = -1

  def initialize(table_config, agent_config)
    @table = Table.new(table_config, agent_config)
    @game_over = false
    @round_over = false
    @current_player = @table.host
    @other_players = @table.children
    deal_starting_hand
    set_player_wind
    set_player_rank
  end

  def step
    states = StateBuilder.build_states(@current_player, @other_players, @table)

    if current_player.tenpai?
      @game_over = true
      reward = RewardCalculator.calculate_tenpai_speed_reward(@current_player, @game_over)
      next_states = StateBuilder.build_states(@current_player, @other_players, @table)
      return [states, ACTION_DONE, reward, next_states, @game_over]
    end

    @game_over = true if can_not_draw?

    if @game_over
      reward = -100
      next_states = StateBuilder.build_states(@current_player, @other_players, @table)
      return [states, ACTION_DONE, reward, next_states, @game_over]
    end

    current_player_draw if !@game_over
    action = @current_player.agent.get_action(states)
    target_tile = current_player.choose(action)
    @current_player.discard(target_tile)
    @current_player.record_hand_status

    next_states = StateBuilder.build_states(@current_player, @other_players, @table)
    reward = RewardCalculator.calculate_tenpai_speed_reward(@current_player, @game_over)
    return [states, action, reward, next_states, @game_over]
  end

  def rotate_turn
    seat_orders = @table.seat_orders
    current_number = seat_orders.find_index(@current_player)
    rotated_orders = seat_orders.rotate(current_number + 1)
    @current_player = rotated_orders.first
    @other_players = rotated_orders[1..]
  end

  def update_epsilon
    @table.players.each { |player| player.agent.update_epsilon }
  end

  def update_agent(states, action, reward, next_states, game_over)
    @current_player.agent.update(states, action, reward, next_states, game_over)
  end

  def sync_qnet
    @table.players.each { |player| player.agent.sync_qnet }
  end

  def log
    Util::Formatter.build_tenpai_speed_log(@table)
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
end
