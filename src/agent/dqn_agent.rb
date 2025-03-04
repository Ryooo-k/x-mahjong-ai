require 'debug'

require 'torch'
require 'numo/narray'

require_relative '../buffer/replay_buffer'

class DQNAgent
  def initialize
    @gamma = 0.98
    @lr = 0.0001
    @epsilon = 0.1
    @buffer_size = 1000
    @batch_size = 32
    @action_size = 14

    @replay_buffer = ReplayBuffer.new(@buffer_size, @batch_size)
    @q_net = QNet.new(@action_size)
    @q_net_target = QNet.new(@action_size)
    @optimizer = Torch::Optim::Adam.new(@q_net.parameters, lr: @lr)
  end

  def get_action(state)
    if rand < @epsilon
      rand(@action_size)
    else
      state_tensor = Torch.tensor(state, dtype: :float32).unsqueeze(0)
      qs = @q_net.call(state_tensor).detach
      qs.numo.argmax
    end
  end

  def update(state, action, reward, next_state, done)
    @replay_buffer.add(state, action, reward, next_state, done)
    return Torch.tensor(0) if @replay_buffer.buffer_size < @batch_size

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
end
