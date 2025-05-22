# frozen_string_literal: true

require 'torch'
require_relative 'replay_buffer'
require_relative '../domain/action_manager'
require_relative '../model/qnet'

class Agent
  def initialize(config)
    @gamma = config['gamma']
    @lr = config['learning_rate']
    @epsilon = config['epsilon']
    @buffer_size = config['buffer_size']
    @batch_size = config['batch_size']
    @action_size = 23
    @min_epsilon = config['min_epsilon']
    @decay_rate = config['decay_rate']
    @device = Torch::Backends::MPS.available? ? "mps" : "cpu"
    @replay_buffer = ReplayBuffer.new(@buffer_size, @batch_size, @device)
    @q_net = QNet.new(config['qnet'], @action_size).to(@device)
    @q_net_target = QNet.new(config['qnet'], @action_size).to(@device)
    @batch_index = Torch.arange(@batch_size, dtype: :long)
    @criterion = Torch::NN::MSELoss.new #平均２乗誤差
    @optimizer = Torch::Optim::Adam.new(@q_net.parameters, lr: @lr)
  end

  def get_action(states, mask)
    if rand < @epsilon
      valid_indices = mask.each_index.select { |i| mask[i] == 1 }
      return valid_indices.sample
    end
  
    tensor_states = Torch.tensor(states, dtype: :float32).unsqueeze(0).to(@device)
    qualities = @q_net.call(tensor_states).detach.squeeze(0)
    masked_qualities = qualities.to_a.each_with_index.map { |q, i| mask[i] == 1 ? q : -Float::INFINITY }
    masked_qualities.each_with_index.max_by { |val, _| val }[1]
  end

  def update(state, action, reward, next_state, done)
    @replay_buffer.add(state, action, reward, next_state, done)
    return Torch.tensor(0) if @replay_buffer.buffers.size < @batch_size

    states, actions, rewards, next_states, donee = @replay_buffer.get_batch
    qualities = @q_net.call(states)
    action_qualities = qualities[@batch_index, actions]

    next_qualities = @q_net_target.call(next_states)
    next_max_qualities = next_qualities.max(1)[0].detach
    targets = rewards + (1 - donee) * @gamma * next_max_qualities
    loss = @criterion.call(action_qualities, targets)

    @optimizer.zero_grad
    loss.backward
    @optimizer.step
    loss.item
  end

  def sync_qnet
    @q_net_target.load_state_dict(@q_net.state_dict)
  end

  def update_epsilon
    @epsilon = [@min_epsilon, @epsilon * @decay_rate].max
  end
end
