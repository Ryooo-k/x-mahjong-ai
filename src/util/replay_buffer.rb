# frozen_string_literal: true

require 'torch'
require 'numo/narray'

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
    @buffers << { state:, action:, reward:, next_state:, done: }
  end

  def get_batch
    data = @buffers.sample(@batch_size)
    states = data.map { |d| d[:state] }
    actions = data.map { |d| d[:action] }
    rewards = data.map { |d| d[:reward] }
    next_states = data.map { |d| d[:next_state] }
    donee = data.map { |d| d[:done] }

    {
      states: Torch.tensor(Numo::NArray.vstack(states), dtype: :float32).to(@device),
      actions: Torch.tensor(Numo::NArray[*actions]).to(@device),
      rewards: Torch.tensor(Numo::NArray[*rewards]).to(@device),
      next_states: Torch.tensor(Numo::NArray.vstack(next_states), dtype: :float32).to(@device),
      donee: Torch.tensor(Numo::NArray[*donee], dtype: :float32).to(@device)
    }
  end
end
