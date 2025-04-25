# frozen_string_literal: true

require 'benchmark'
require_relative '../util/file_loader'
require_relative '../environment/env'

def run_training
  config = Util::FileLoader.load_parameter('experiment_1')
  env = MahjongEnv.new(config['table'], config['player'])
  second = Benchmark.realtime { run_training_loop(config['train'], env) }
  puts format_second(second)
end

def run_training_loop(train_config, env)
  train_config['count'].times do |count|
    done = false
    env.reset

    while not done
      current_player = env.current_player
      env.player_draw
      states = env.states
      action = current_player.get_discard_action(states)
      next_states, reward, done, discard_tile = env.step(action)
      current_player.update_discard_agent(states, action, reward, next_states, done)
      env.rotate_turn
    end

    env.sync_qnet_for_all_players if count % train_config['qnet_sync_interval'] == 0
    puts "学習回数：#{count}" if count % 10 == 0
    puts env.log_training_info if count % 10 == 0
  end
end

def format_second(second)
  hours = second / 3600
  minutes = (second % 3600) / 60
  "#{hours.to_i}時間 #{minutes.to_i}分 #{second.to_i}秒"
end
