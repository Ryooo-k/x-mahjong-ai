# frozen_string_literal: true

require 'torch'
require 'numo/narray'
require_relative '../../src/util/replay_buffer'

class OneselfAgent
  def initialize
    @gamma = 0.98
    @lr = 0.0001
    @epsilon = 0.1
    @buffer_size = 1000
    @batch_size = 32
    @action_size = 14

    @device = Torch.device(Torch::Backends::MPS.available? ? "mps" : "cpu")

    @replay_buffer = ReplayBuffer.new(@buffer_size, @batch_size, @device)
    @q_net = QNet.new(@action_size).to(@device)
    @q_net_target = QNet.new(@action_size).to(@device)
    @optimizer = Torch::Optim::Adam.new(@q_net.parameters, lr: @lr)
  end

  def get_action(state)
    if rand < @epsilon
      rand(@action_size)
    else
      state_tensor = Torch.tensor(state, dtype: :float32).unsqueeze(0)
      state_gpu = state_tensor.to(@device)
      qs = @q_net.call(state_gpu).detach
      qs.numo.argmax
    end
  end

  def update(state, action, reward, next_state, done)
    @replay_buffer.add(state.cpu, action, reward, next_state.cpu, done)
    return Torch.tensor(0) if @replay_buffer.buffers.size < @batch_size

    states, actions, rewards, next_states, donee = @replay_buffer.get_batch
    indices = Torch.arange(@batch_size, dtype: :long)
    all_qs = @q_net.call(states)
    action_qs = all_qs[indices, actions]

    next_all_qs = @q_net_target.call(next_states)
    next_qs = next_all_qs.max(1)[0].detach
    targets = rewards + (1 - donee) * @gamma * next_qs
    criterion = Torch::NN::MSELoss.new #平均２乗誤差
    loss = criterion.call(action_qs, targets)

    @optimizer.zero_grad
    loss.backward
    @optimizer.step
    loss.data
  end

  def sync_qnet
    @q_net_target.load_state_dict(@q_net.state_dict)
  end

  def updata_epsilon
    min_epsilon = 0.01
    decay_rate = 0.99999
    @epsilon = [min_epsilon, @epsilon * decay_rate].max
  end
end
