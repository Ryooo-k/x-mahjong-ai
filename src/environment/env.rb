# frozen_string_literal: true

require_relative 'state_builder'
require_relative '../domain/table'
require_relative '../domain/action_handler'
require_relative '../domain/action_manager'
require_relative '../util/formatter'

class Env
  attr_reader :table, :current_player, :other_players

  ActionHandler = Domain::ActionHandler
  ActionManager = Domain::ActionManager
  STARTING_HAND_COUNT = 13
  ACTION_NUMBER = 1

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
    current_player_draw
    states_list = StateBuilder.build_states_list(@current_player, @other_players, @table)
    current_player_states = states_list[0]

    tsumo_actions = ActionHandler.handle_tsumo_action(@current_player, @other_players, @table, current_player_states)
    next_states_list = StateBuilder.build_states_list(@current_player, @other_players, @table)
    @round_over = true if tsumo_actions[0] == ActionManager::TSUMO_INDEX
    check_game_over
    rewards = RewardCalculator.calculate_tsumo_rewards(@current_player, @other_players, @round_over)
    update_agent(states_list, tsumo_actions, rewards, next_states_list, @game_over)
    return if tsumo_actions[0] == ActionManager::TSUMO_INDEX

    discard_action, discarded_tile = ActionHandler.handle_discard_action(@current_player, @other_players, @table, current_player_states)
    # ActionHandler.handle_ron_action(@current_player, @other_players, @table, discarded_tile)
    @round_over = can_not_draw?

    check_game_over
    pass = ActionManager::PASS_INDEX
    discard_actions = [discard_action, pass, pass, pass]
    next_states_list = StateBuilder.build_states_list(@current_player, @other_players, @table)
    rewards = RewardCalculator.calculate_discard_rewards(@current_player, @other_players, @round_over)
    update_agent(states_list, discard_actions, rewards, next_states_list, @game_over)
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

  def sync_qnet
    @table.players.each { |player| player.agent.sync_qnet }
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

  def update_agent(states_list, actions, rewards, next_states_list, game_over)
    all_players = [@current_player] + @other_players
    all_players.each_with_index do |player, i|
      player.agent.update(states_list[i], actions[i], rewards[i], next_states_list[i], game_over)
    end
  end
end
