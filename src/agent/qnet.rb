require 'torch'
require 'numo/narray'

include Torch::NN

class QNet < Torch::NN::Module
  def initialize(action_size)
    super()
    @l1 = Linear.new(38, 256)
    @l2 = Linear.new(256, 128)
    @l3 = Linear.new(128, 64)
    @l4 = Linear.new(64, action_size)
  end

  def forward(x)
    y = Functional.relu(@l1.call(x))
    y = Functional.relu(@l2.call(y))
    y = Functional.relu(@l3.call(y))
    @l4.call(y)
  end
end
