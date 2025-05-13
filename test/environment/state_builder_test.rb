# frozen_string_literal: true

require 'test/unit'
require_relative '../util/file_loader'
require_relative '../../src/environment/state_builder'
require_relative '../../src/environment/env'

class StateBuilderTest < Test::Unit::TestCase
  def setup
    parameter = FileLoader.load_parameter
    @env = Env.new(parameter['table'], parameter['player'])
  end

  def test_build_all_player_states_return_array_of_four_tensors
    states = StateBuilder.build_all_player_states(@env.current_player, @env.other_players, @env.table)

    assert_equal Array, states.class
    assert_equal 4, states.size
    states.each do |state|
      assert_instance_of Torch::Tensor, state
    end
  end

  def test_each_player_state_has_217_elements
    states = StateBuilder.build_all_player_states(@env.current_player, @env.other_players, @env.table)

    states.each do |state|
      assert_equal 217, state.length
    end
  end
end
