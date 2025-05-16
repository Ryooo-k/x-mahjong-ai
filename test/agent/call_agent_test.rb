# frozen_string_literal: true

require 'test/unit'
require 'yaml'
require_relative '../../src/agent/call_agent'
require_relative '../util/file_loader'

class CallAgentTest < Test::Unit::TestCase
  class DummyBuffer
    attr_reader :buffers

    def initialize
      @buffers = []
    end

    def add(*); end

    def get_batch
      batch_size = 2
      [
        Torch.randn([batch_size, 38]),      # states
        Torch.tensor([0, 1]),               # actions
        Torch.tensor([1.0, 0.0]),           # rewards
        Torch.randn([batch_size, 38]),      # next_states
        Torch.tensor([0.0, 1.0])            # donee
      ]
    end
  end

  class DummyQNet
    def call(x)
      Torch.tensor([[1.0, 5.0], [3.0, 0.5]])   # argmax_index[0] = 1
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
    config = FileLoader.load_parameter
    @agent = CallAgent.new(config['player']['call_agent'])
    @agent.instance_variable_set(:@replay_buffer, DummyBuffer.new)
    @agent.instance_variable_set(:@q_net, DummyQNet.new)
    @agent.instance_variable_set(:@q_net_target, DummyQNet.new)
    @agent.instance_variable_set(:@criterion, DummyCriterion.new)
    @agent.instance_variable_set(:@optimizer, DummyOptimizer.new)
  end

  def test_get_action_return_argmax_when_epsilon_is_zero
    input = [0.1] * 38
    action = @agent.get_action(input)
    assert_equal 1, action  # 期待値: mock_qnetのargmax_index の 1 を期待する
  end

  def test_get_action_return_random_when_epsilon_is_high
    @agent.instance_variable_set(:@epsilon, 1.0)  # 必ず探索を行う設定
    input = [0.1] * 38
    action = @agent.get_action(input)
    action_size = 14
    assert_includes (0...action_size).to_a, action
  end

  def test_update_return_zero_when_buffer_is_small
    dummy_state = Torch.tensor(1.0)
    loss = @agent.update(dummy_state, nil, nil, dummy_state, nil)
    assert_equal 0, loss.item
  end

  def test_update_return_loss_tensor
    dummy_state = Torch.tensor(1.0)
    buffer = DummyBuffer.new
    buffer.buffers << [] << []  # バッチサイズと同じ数を入れておく
    @agent.instance_variable_set(:@replay_buffer, buffer)
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
    qnet = { layer1: 38, layer: 68 }
    epsilon = 1.0
    decay_rate = 0.9
    config = {
      'gamma' => 0.9,
      'learning_rate' => 0.001,
      'epsilon' => epsilon,
      'buffer_size' => 1,
      'batch_size' => 1,
      'min_epsilon' => 0.1,
      'decay_rate' => decay_rate,
      'qnet' => qnet
    }

    agent = CallAgent.new(config)
    agent.update_epsilon
    expected = epsilon * decay_rate
    assert_equal expected, agent.instance_variable_get(:@epsilon)
  end

  def test_update_epsilon_does_not_go_below_min
    qnet = { layer1: 38, layer: 68 }
    min_epsilon = 0.5
    config = {
      'gamma' => 0.9,
      'learning_rate' => 0.001,
      'epsilon' => 0.01,
      'buffer_size' => 1,
      'batch_size' => 1,
      'min_epsilon' => min_epsilon,
      'decay_rate' => 0.1,
      'qnet' => qnet
    }

    agent = CallAgent.new(config)
    agent.update_epsilon
    assert_equal min_epsilon, agent.instance_variable_get(:@epsilon)
  end  
end
