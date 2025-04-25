# frozen_string_literal: true

require 'torch'
require 'numo/narray'
require_relative '../model/qnet'
require_relative '../util/replay_buffer'

class DiscardAgent
  def initialize(config)
    @gamma = config['gamma']
    @lr = config['learning_rate']
    @epsilon = config['epsilon']
    @buffer_size = config['buffer_size']
    @batch_size = config['batch_size']
    @action_size = 14
    @min_epsilon = config['min_epsilon']
    @decay_rate = config['decay_rate']
    @device = Torch.device(Torch::Backends::MPS.available? ? "mps" : "cpu")
    @replay_buffer = ReplayBuffer.new(@buffer_size, @batch_size, @device)
    @q_net = QNet.new(config['qnet'], @action_size).to(@device)
    @q_net_target = QNet.new(config['qnet'], @action_size).to(@device)
    @criterion = Torch::NN::MSELoss.new #平均２乗誤差
    @optimizer = Torch::Optim::Adam.new(@q_net.parameters, lr: @lr)
  end

  def get_action(states)
    return rand(@action_size) if rand < @epsilon

    tensor_states = Torch.tensor(states, dtype: :float32).unsqueeze(0).to(@device)
    qualities = @q_net.call(tensor_states).detach
    qualities.argmax(1)[0].item
  end

  def update(state, action, reward, next_state, done)
    @replay_buffer.add(state.cpu, action, reward, next_state.cpu, done)
    return Torch.tensor(0) if @replay_buffer.buffers.size < @batch_size

    states, actions, rewards, next_states, donee = @replay_buffer.get_batch
    batch_number = Torch.arange(@batch_size, dtype: :long)
    qualities = @q_net.call(states)
    action_qualities = qualities[batch_number, actions]

    next_qualities = @q_net_target.call(next_states)
    next_max_qualities = next_qualities.max(1)[0].detach
    targets = rewards + (1 - donee) * @gamma * next_max_qualities
    loss = @criterion.call(action_qualities, targets)

    @optimizer.zero_grad
    loss.backward
    @optimizer.step
    loss.data
  end

  def observe
  end

  def sync_qnet
    @q_net_target.load_state_dict(@q_net.state_dict)
  end

  def update_epsilon
    @epsilon = [@min_epsilon, @epsilon * @decay_rate].max
  end
end
