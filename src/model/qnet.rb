# frozen_string_literal: true

require 'torch'

include Torch::NN

class QNet < Torch::NN::Module
  def initialize(layer_config, action_size)
    super()
    build_linear(layer_config, action_size)
  end

  def forward(states)
    default_instance_size = 5
    layer_size = instance_variables.size - default_instance_size
    cal_qualities(layer_size, states)
  end

  private

  def build_linear(layer_config, action_size)
    layers = layer_config.map { |_, v| v}
    layers.each_with_index do |input, index|
      next_index = index + 1
      output = next_index == layers.size ? action_size : layers[next_index]
      instance_variable_set("@l#{next_index}", Linear.new(input, output))
    end
  end

  def cal_qualities(layer_size, states)
    qualities = Functional.relu(@l1.call(states))
    (layer_size - 1).times do |i|
      layer_number = i + 2
      layer = instance_variable_get("@l#{layer_number}")
      qualities = layer_number != layer_size ? Functional.relu(layer.call(qualities)) : layer.call(qualities)
    end
    qualities
  end
end
