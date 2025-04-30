# frozen_string_literal: true

require 'test/unit'
require_relative '../../src/agent/replay_buffer'

class ReplayBufferTest < Test::Unit::TestCase
  def setup
    @buffer_size = 3
    @batch_size = 2
    @device = Torch::Backends::MPS.available? ? "mps" : "cpu"
    @replay_buffer = ReplayBuffer.new(@buffer_size, @batch_size, @device)
  end

  def test_add_experience_to_buffer
    state = Torch.tensor(0)
    action = 0
    reward = 0
    next_state = Torch.tensor(0)
    done = false
    @replay_buffer.add(state, action, reward, next_state, done)
    assert_equal(1, @replay_buffer.buffers.size)

    @replay_buffer.add(state, action, reward, next_state, done)
    assert_equal(2, @replay_buffer.buffers.size)
  end

  def test_remove_oldest_when_buffer_is_full
    # bufferサイズ3のため、4回addしている。
    state_1 = Torch.tensor(1)
    state_2 = Torch.tensor(2)
    state_3 = Torch.tensor(3)
    state_4 = Torch.tensor(4)
    action = 0
    reward = 0
    done = false

    @replay_buffer.add(state_1, action, reward, state_1, done)
    @replay_buffer.add(state_2, action, reward, state_2, done)
    @replay_buffer.add(state_3, action, reward, state_3, done)
    @replay_buffer.add(state_4, action, reward, state_4, done)

    states = @replay_buffer.buffers.map { |buffer| buffer[:state] }
    result = states.any? { |state| state.equal?(state_1) }
    assert_equal false, result
  end

  def test_gat_batch_return_sample_data
    state = Torch.tensor(1)
    action = 0
    reward = 0
    done = false
    10.times { |data| @replay_buffer.add(state, action, reward, state, done) }

    sample_data = @replay_buffer.get_batch
    state_size = sample_data[0].length
    action_size = sample_data[1].length
    reward_size = sample_data[2].length
    next_state_size = sample_data[3].length
    done_size = sample_data[4].length

    assert_equal(@batch_size, state_size)
    assert_equal(@batch_size, action_size)
    assert_equal(@batch_size, reward_size)
    assert_equal(@batch_size, next_state_size)
    assert_equal(@batch_size, done_size)
  end
end
