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
  
  def test_build_discard_state_return_tensor_of_217_elements
    player_states = StateBuilder.build_discard_states(@env.current_player, @env.other_players, @env.table)
    assert_equal 217, player_states.length
    player_states.each do |state|
      assert_instance_of Torch::Tensor, state
    end
  end

  def test_build_tsumo_state_return_tensor_of_7_elements
    player_states = StateBuilder.build_tsumo_states(@env.current_player, @env.other_players, @env.table)
    assert_equal 7, player_states.length
    player_states.each do |state|
      assert_instance_of Torch::Tensor, state
    end
  end

  def test_build_tsumo_next_state_return_tensor_of_7_elements
    player_states = StateBuilder.build_tsumo_states(@env.current_player, @env.other_players, @env.table)
    assert_equal 7, player_states.length
    player_states.each do |state|
      assert_instance_of Torch::Tensor, state
    end
  end

  def test_build_ron_state_return_tensor_of_7_elements
    is_ron = false
    player_states = StateBuilder.build_ron_states(is_ron, @env.current_player, @env.other_players, @env.table)
    assert_equal 7, player_states.length
    player_states.each do |state|
      assert_instance_of Torch::Tensor, state
    end
  end

  def test_build_ron_next_state_return_tensor_of_7_elements
    player_states = StateBuilder.build_ron_next_states(@env.current_player, @env.other_players, @env.table)
    assert_equal 7, player_states.length
    player_states.each do |state|
      assert_instance_of Torch::Tensor, state
    end
  end
end
