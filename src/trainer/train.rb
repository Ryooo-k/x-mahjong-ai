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
      game_over = false
      round_over = false
      time = 0

      while not game_over
        while not round_over
          env.step
          round_over = env.round_over?
          env.rotate_turn if !round_over
        end

        puts env.log
        env.renchan? ? env.restart : env.proceed_to_next_round
        round_over = env.round_over?
        env.check_game_over
        game_over = env.game_over?
      end

      env.sync_qnet if count % train_config['qnet_sync_interval'] == 0
    end

    total_time += time_taken
    output(total_time, count) if count % 100 == 0
    env.reset
  end
end

def output(time_taken, count)
  puts format_second(time_taken)
  puts "学習回数：#{count}"
end

def format_second(time_taken)
  hours = time_taken / 3600
  minutes = (time_taken % 3600) / 60
  "#{hours.to_i}時間 #{minutes.to_i}分"
end
