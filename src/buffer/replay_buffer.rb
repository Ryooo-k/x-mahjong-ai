require 'debug'

require 'torch'
require 'numo/narray'

class ReplayBuffer
  def initialize(buffer_size, batch_size)
    @buffer = []
    @buffer_size = buffer_size
    @batch_size = batch_size
  end

  def add(state, action, reward, next_state, done)
    @buffer.shift if @buffer.size >= @buffer_size
    @buffer << [state, action, reward, next_state, done]
  end

  def buffer_size
    @buffer.size
  end

  def get_batch
    data = @buffer.sample(@batch_size)
    state = data.map {|d| d[0]}
    action = data.map {|d| d[1]}
    reward = data.map {|d| d[2]}
    next_state = data.map {|d| d[3]}
    done = data.map {|d| d[4]}

    [
      Torch.tensor(Numo::NArray.vstack(state), dtype: :float32),
      Torch.tensor(Numo::NArray[*action]),
      Torch.tensor(Numo::NArray[*reward]),
      Torch.tensor(Numo::NArray.vstack(next_state), dtype: :float32),
      Torch.tensor(Numo::NArray[*done], dtype: :float32)
    ]
  end
end
