# frozen_string_literal: true
require 'debug'
require 'benchmark'
require_relative '../util/file_loader'
require_relative '../environment/env'
require_relative '../agent/player_agent'

def run_training
  config = FileLoader.load_parameter('experiment_1')
  env = MahjongEnv.new(config['table'], config['player'])
  time_taken = Benchmark.realtime { run_training_loop(config['train'], env) }
  puts time_taken
end

def run_training_loop(train_config, env)
  # binding.break
  train_config['count'].times do |count|
    done = false
    env.reset
    start_info = env.info

    while not done
      current_player = env.current_player
      other_players = env.other_players
      env.player_draw
      states = env.states
      action = current_player.get_discard_action(states)
      next_states, reward, done, target = env.step(action)
      # call_result = env.process_call_phase(target)
      current_player.update_discard_agent(states, action, reward, next_states, done)
      env.rotate_turn
    end

    agent.sync_qnet if count != 0 && count % train_config['sync_interval'] == 0
    average_loss = total_loss / env.order
    output(start_info, end_info) if count % 10 == 0
  end
end

def output(start_info, end_info)
  puts "配牌：#{to_tiles(start_hands)}、向聴数：#{start_shanten}"
  puts "最終：#{to_tiles(env.hands.sort)}、向聴数：#{env.shanten}"
  puts "アベレージロス：#{average_loss}"
  puts "終了順目：#{env.order}"
  puts "学習回数：#{count}"
  puts ''
end
