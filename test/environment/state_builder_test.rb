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
  
  def test_build_player_state_return_tensor_of_217_elements
    player_states = StateBuilder.build_player_states(@env.current_player, @env.other_players, @env.table)
    assert_equal 217, player_states.length
    player_states.each do |state|
      assert_instance_of Torch::Tensor, state
    end
  end

  def test_build_all_player_states_return_array_of_four_elements
    all_player_states = StateBuilder.build_all_player_states(@env.current_player, @env.other_players, @env.table)
    assert_equal Array, all_player_states.class
    assert_equal 4, all_player_states.size
  end

  def test_all_player_states_match_individual_player_states
    current_player_states = StateBuilder.build_player_states(@env.current_player, @env.other_players, @env.table)
    @env.rotate_turn
    lower_player_states = StateBuilder.build_player_states(@env.current_player, @env.other_players, @env.table)
    @env.rotate_turn
    opposite_player_states = StateBuilder.build_player_states(@env.current_player, @env.other_players, @env.table)
    @env.rotate_turn
    upper_player_states = StateBuilder.build_player_states(@env.current_player, @env.other_players, @env.table)
    @env.rotate_turn

    all_player_states = StateBuilder.build_all_player_states(@env.current_player, @env.other_players, @env.table)
    assert_equal current_player_states.to_s, all_player_states[0].to_s
    assert_not_equal current_player_states.to_s, all_player_states[1].to_s
    assert_not_equal current_player_states.to_s, all_player_states[2].to_s
    assert_not_equal current_player_states.to_s, all_player_states[3].to_s

    assert_equal lower_player_states.to_s, all_player_states[1].to_s
    assert_not_equal lower_player_states.to_s, all_player_states[0].to_s
    assert_not_equal lower_player_states.to_s, all_player_states[2].to_s
    assert_not_equal lower_player_states.to_s, all_player_states[3].to_s

    assert_equal opposite_player_states.to_s, all_player_states[2].to_s
    assert_not_equal opposite_player_states.to_s, all_player_states[0].to_s
    assert_not_equal opposite_player_states.to_s, all_player_states[1].to_s
    assert_not_equal opposite_player_states.to_s, all_player_states[3].to_s

    assert_equal upper_player_states.to_s, all_player_states[3].to_s
    assert_not_equal upper_player_states.to_s, all_player_states[0].to_s
    assert_not_equal upper_player_states.to_s, all_player_states[1].to_s
    assert_not_equal upper_player_states.to_s, all_player_states[2].to_s
  end
end
