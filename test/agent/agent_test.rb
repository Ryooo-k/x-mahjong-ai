# frozen_string_literal: true

require 'test/unit'
require 'yaml'
require_relative '../../src/agent/agent'
require_relative '../../src/util/file_loader'

class AgentTest < Test::Unit::TestCase
  class DummyBuffer
    attr_reader :buffers

    def initialize
      @buffers = []
    end

    def add(*); end

    def get_batch
      batch_size = 32
      [
        Torch.randn(batch_size, 1), # states
        Torch.tensor([1]), # actions
        Torch.tensor([1.0]), # rewards
        Torch.randn(batch_size, 1), # next_states
        Torch.tensor([1.0]) # donee
      ]
    end
  end

  class DummyQNet
    def call(x)
      Torch.tensor([[1.0, 2.0, 3.0, 4.0]]) # argmax_index = 3
    end
  end

  class DummyCriterion
    def call(qualities, targets)
      Torch.tensor(999.0, requires_grad: true)
    end
  end

  class DummyOptimizer
    def zero_grad; end
    def step; end
  end

  def setup
    @config = Util::FileLoader.load_parameter('experiment_1')
    @agent = Agent.new(@config['agent'])
    @agent.instance_variable_set(:@replay_buffer, DummyBuffer.new)
    @agent.instance_variable_set(:@q_net, DummyQNet.new)
    @agent.instance_variable_set(:@q_net_target, DummyQNet.new)
    @agent.instance_variable_set(:@criterion, DummyCriterion.new)
    @agent.instance_variable_set(:@optimizer, DummyOptimizer.new)
  end

  def test_get_action_return_argmax_when_epsilon_is_zero
    @agent.instance_variable_set(:@epsilon, 0)  # ランダム行動無し
    states = [0.1] * 38
    mask = [1] * 4
    action = @agent.get_action(states, mask)
    assert_equal 3, action  # 期待値: mock_qnetのargmax_index の 3 を期待する
  end

  def test_get_action_return_random_in_mask_when_epsilon_is_high
    @agent.instance_variable_set(:@epsilon, 1.0)  # 必ず探索を行う
    states = [0.1] * 38
    mask = [1, 0, 1, 0] # index 0 か 2 のどちらかを選択する 
    action = @agent.get_action(states, mask)
    assert_includes [0, 2], action
  end

  def test_update_return_zero_when_buffer_is_small
    dummy_state = Torch.tensor(1.0)
    loss = @agent.update(dummy_state, nil, nil, dummy_state, nil)
    assert_equal 0, loss.item
  end

  def test_update_return_loss_tensor
    dummy_state = Torch.tensor(1.0)
    buffer_size = @config['agent']['buffer_size']
    buffer = DummyBuffer.new
    buffer_size.times { |_| buffer.buffers << [] }  # バッチサイズと同じ数を入れておく
    @agent.instance_variable_set(:@replay_buffer, buffer)
    @agent.instance_variable_set(:@batch_index, Torch.arange(1, dtype: :long)) # DummyQnetのバッチ数１に合わせる
    loss = @agent.update(dummy_state, nil, nil, dummy_state, nil)
    assert_instance_of Float, loss
    assert_equal 999.0, loss # DummyCriterionのcallメソッドの戻り値と一致していること
  end

  def test_sync_qnet_copies_weights
    layer_config = { layer1: 38, layer: 68 }
    action_size = 14
    qnet1 = QNet.new(layer_config, action_size)
    qnet2 = QNet.new(layer_config, action_size)
    refute_equal(qnet1.state_dict.to_s, qnet2.state_dict.to_s)  

    qnet2.load_state_dict(qnet1.state_dict)
    assert_equal qnet1.state_dict.to_s, qnet2.state_dict.to_s
  end

  def test_update_epsilon_decreases_properly
    epsilon = 1.0
    decay_rate = 0.9
    @agent.instance_variable_set(:@epsilon, epsilon)
    @agent.instance_variable_set(:@decay_rate, decay_rate)

    @agent.update_epsilon
    expected = epsilon * decay_rate
    assert_equal expected, @agent.instance_variable_get(:@epsilon)
  end

  def test_update_epsilon_does_not_go_below_min
    epsilon = 1.0
    decay_rate = 0.9
    min_epsilon = 0.95
    @agent.instance_variable_set(:@epsilon, epsilon)
    @agent.instance_variable_set(:@decay_rate, decay_rate)
    @agent.instance_variable_set(:@min_epsilon, min_epsilon)

    @agent.update_epsilon
    assert_equal min_epsilon, @agent.instance_variable_get(:@epsilon)
  end  
end
