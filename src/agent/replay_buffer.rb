# frozen_string_literal: true

require 'torch'

class ReplayBuffer
  attr_reader :buffers

  def initialize(max_buffer_size, batch_size, device)
    @buffers = []
    @max_buffer_size = max_buffer_size
    @batch_size = batch_size
    @device = device
  end

  def add(state, action, reward, next_state, done)
    @buffers.shift if @buffers.size >= @max_buffer_size
    @buffers << { state: state.cpu, action:, reward:, next_state: next_state.cpu, done: }
  end

  def get_batch
    data = @buffers.sample(@batch_size)
    states = data.map { |d| d[:state] }
    actions = data.map { |d| d[:action] }
    rewards = data.map { |d| d[:reward] }
    next_states = data.map { |d| d[:next_state] }
    donee = data.map { |d| d[:done] ? 1.0 : 0.0 }

    [
      Torch.stack(states).to(@device),
      Torch.tensor(actions, dtype: :int32, device: @device),
      Torch.tensor(rewards, dtype: :int32, device: @device),
      Torch.stack(next_states).to(@device),
      Torch.tensor(donee, dtype: :float32, device: @device)
    ]
  end
end
