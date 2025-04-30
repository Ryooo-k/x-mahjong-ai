# frozen_string_literal: true

require 'benchmark'
require_relative '../util/file_loader'
require_relative '../environment/env'

def run_training
  config = Util::FileLoader.load_parameter('experiment_1')
  env = Env.new(config['table'], config['player'])
  time_taken = Benchmark.realtime { run_training_loop(config['train'], env) }
  puts format_second(time_taken)
end

def run_training_loop(train_config, env)
  total_time = 0
  train_config['count'].times do |count|
    time_taken = Benchmark.realtime do |_|
      done = false
      env.reset
      time = 0

      while not done
        current_player = env.current_player
        env.player_draw
        states = env.states
        action = current_player.get_discard_action(states)
        next_states, reward, done, discarded_tile = env.step(action)
        current_player.update_discard_agent(states, action, reward, next_states, done)
        env.rotate_turn
      end

      env.sync_qnet_for_all_players if count % train_config['qnet_sync_interval'] == 0
    end
    total_time += time_taken
    output(total_time, count, env.training_log) if count % 10 == 0
  end
end

def output(time_taken, count, log)
  puts format_second(time_taken)
  puts "学習回数：#{count}"
  puts log
end

def format_second(time_taken)
  hours = time_taken / 3600
  minutes = (time_taken % 3600) / 60
  "#{hours.to_i}時間 #{minutes.to_i}分"
end
