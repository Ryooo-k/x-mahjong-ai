# frozen_string_literal: true

require 'test/unit'
require_relative '../../src/util/replay_buffer'

class ReplayBufferTest < Test::Unit::TestCase
  def setup
    @buffer_size = 10
    @batch_size = 3
    device = Torch.device("mps")
    @replay_buffer = ReplayBuffer.new(@buffer_size, @batch_size, device)
  end

  def test_add_experience_to_buffer
    state = 0
    action = 0
    reward = 0
    next_state = 1
    done = false
    @replay_buffer.add(state, action, reward, next_state, done)
    assert_equal(1, @replay_buffer.buffers.size)

    @replay_buffer.add(state, action, reward, next_state, done)
    assert_equal(2, @replay_buffer.buffers.size)
  end

  def test_remove_oldest_when_buffer_is_full
    (@buffer_size + 1).times { |data| @replay_buffer.add(data, data, data, data, false) }
    assert_equal(@buffer_size, @replay_buffer.buffers.size)
    states = @replay_buffer.buffers.map { |buffer| buffer[:state] }
    assert_not_includes(states, 0)
  end

  def test_gat_batch_return_sample_data
    10.times { |data| @replay_buffer.add(data, data, data, data, false) }
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
