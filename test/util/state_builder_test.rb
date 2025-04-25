# frozen_string_literal: true

require 'test/unit'
require_relative '../../src/util/state_builder'
require_relative '../../src/environment/env'
require_relative 'file_loader'

class StateBuilderTest < Test::Unit::TestCase
  def setup
    @builder = Util::StateBuilder
    parameter = FileLoader.load_parameter
    @env = Env.new(parameter['table'], parameter['player'])
    @table = Table.new(parameter['table'], parameter['player'])
  end

  def test_build_states_return_697_values
    current_player = @env.current_player
    other_players = @env.other_players
    states = @builder.build_states(current_player, other_players, @table)
    assert_equal 697, states.length
  end

  def test_build_states_return_tensor_data
    current_player = @env.current_player
    other_players = @env.other_players
    states = @builder.build_states(current_player, other_players, @table)
    assert_equal Torch::Tensor, states.class
  end
end
