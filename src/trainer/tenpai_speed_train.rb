# frozen_string_literal: true

require 'benchmark'
require_relative '../util/file_loader'
require_relative '../environment/tenpai_speed_env'

def run_training
  config = Util::FileLoader.load_parameter('tenpai_speed')
  env = Env.new(config['table'])
  time_taken = Benchmark.realtime { run_training_loop(config['train'], env) }
  puts format_second(time_taken)
end

def run_training_loop(train_config, env)
  total_time = 0
  train_config['count'].times do |count|
    time_taken = Benchmark.realtime do |_|
      game_over = false
      time = 0

      while not game_over
        4.times do  |_|
          states, action, reward, next_states, game_over = env.step
          env.update_agent(states, action, reward, next_states, game_over)
          env.rotate_turn
        end
        game_over = env.game_over?
      end

      puts env.log if env.table.draw_count != 122
      env.update_epsilon
      env.sync_qnet if count % train_config['qnet_sync_interval'] == 0
    end

    total_time += time_taken
    output(total_time, count, env.log) if count % 100 == 0
    env.reset
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
