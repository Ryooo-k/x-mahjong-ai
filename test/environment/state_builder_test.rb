# frozen_string_literal: true

require 'test/unit'
require_relative '../util/file_loader'
require_relative '../../src/environment/state_builder'
require_relative '../../src/environment/env'

class StateBuilderTest < Test::Unit::TestCase
  def setup
    @builder = StateBuilder
    parameter = FileLoader.load_parameter
    @env = Env.new(parameter['table'], parameter['player'])
  end

  def test_build_states_return_693_values
    current_player = @env.current_player
    other_players = @env.other_players
    states = @builder.build_states(current_player, other_players, @env.table)
    assert_equal 693, states.length
  end

  def test_build_states_return_tensor_data
    current_player = @env.current_player
    other_players = @env.other_players
    states = @builder.build_states(current_player, other_players, @env.table)
    assert_equal Torch::Tensor, states.class
  end
end
