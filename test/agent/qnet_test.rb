# frozen_string_literal: true

require 'test/unit'
require_relative '../../src/agent/qnet'

class QNetTest < Test::Unit::TestCase
  def setup
    @layer_config = {
      layer1: 38,
      layer2: 256,
      layer3: 128,
      layer4: 64    
    }
    @action_size = 14
    @qnet = QNet.new(@layer_config, @action_size)
  end

  def test_instance_variable_count_matches_config
    @qnet.parameters
    default_instance_size = 5
    layer_size = @qnet.instance_variables.size - default_instance_size
    assert_equal(@layer_config.size, layer_size)
  end

  def test_forward_returns_tensor
    input = Torch.randn([1, 38])  # バッチサイズ1、特徴量38
    output = @qnet.forward(input)
    assert_instance_of(Torch::Tensor, output)
  end

  def test_forward_output_shape
    batch_size = 4
    input = Torch.randn([batch_size, 38])  # バッチサイズ4、特徴量38
    output = @qnet.forward(input)
    assert_equal([batch_size, @action_size], output.shape)
  end
end
