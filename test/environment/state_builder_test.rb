# frozen_string_literal: true

require 'test/unit'
require_relative '../util/file_loader'
require_relative '../../src/environment/state_builder'
require_relative '../../src/environment/env'
require_relative '../../src/domain/tile'

class StateBuilderTest < Test::Unit::TestCase
  def setup
    parameter = FileLoader.load_parameter
    env = Env.new(parameter['table'], parameter['agent'])
    @current_player = env.current_player
    @other_players = env.other_players
    @table = env.table
    @tiles = Array.new(135) { |id| Tile.new(id) }
  end

  def test_build_states_list
    all_players = [@current_player] + @other_players
    scores = [0, 10_000, 20_000, 30_000]
    normalized_scores = [0.0, 0.1, 0.2, 0.3]

    all_players.each_with_index do |p, i|
      p.instance_variable_set(:@hands, [])
      p.instance_variable_set(:@score, scores[i])
      p.instance_variable_set(:@hand_histories, [[]])
    end

    @table.instance_variable_set(:@draw_count, 0)
    @table.tile_wall.instance_variable_set(:@open_dora_indicators, [])

    current_player_main_states = [0] * 34 + [-1.0] * 40 + [0] + [1] + [normalized_scores[0]] + [6] + [0.0]
    current_player_sub_states = [-1.0] * 40 + [0] + [1] + [normalized_scores[0]]

    lower_seat_player_main_states = [0] * 34 + [-1.0] * 40 + [0] + [1] + [normalized_scores[1]] + [6] + [0.0]
    lower_seat_player_sub_states = [-1.0] * 40 + [0] + [1] + [normalized_scores[1]]

    opposite_player_main_states = [0] * 34 + [-1.0] * 40 + [0] + [1] + [normalized_scores[2]] + [6] + [0.0]
    opposite_player_sub_states = [-1.0] * 40 + [0] + [1] + [normalized_scores[2]]

    upper_seat_player_main_states = [0] * 34 + [-1.0] * 40 + [0] + [1] + [normalized_scores[3]] + [6] + [0.0]
    upper_seat_player_sub_states = [-1.0] * 40 + [0] + [1] + [normalized_scores[3]]

    table_states = [1.0, -1.0, -1.0, -1.0, -1.0, -1.0, 0, 0.0, 0.0]

    current_player_states = Torch.tensor(current_player_main_states + lower_seat_player_sub_states + opposite_player_sub_states + upper_seat_player_sub_states + table_states, dtype: :float32)
    lower_seat_player_states = Torch.tensor(lower_seat_player_main_states + opposite_player_sub_states + upper_seat_player_sub_states + current_player_sub_states + table_states, dtype: :float32)
    opposite_player_states = Torch.tensor(opposite_player_main_states + upper_seat_player_sub_states + current_player_sub_states + lower_seat_player_sub_states + table_states, dtype: :float32)
    upper_seat_player_states = Torch.tensor(upper_seat_player_main_states + current_player_sub_states + lower_seat_player_sub_states + opposite_player_sub_states + table_states, dtype: :float32)

    states_list = StateBuilder.build_states_list(@current_player, @other_players, @table)
    assert_equal current_player_states.to_s, states_list[0].to_s
    assert_equal lower_seat_player_states.to_s, states_list[1].to_s
    assert_equal opposite_player_states.to_s, states_list[2].to_s
    assert_equal upper_seat_player_states.to_s, states_list[3].to_s
  end

  def test_build_tsumo_action_mask
    # 和了手: 111222萬 333筒 456索 東東
    agari_hands = [
      @tiles[0], @tiles[1], @tiles[2],
      @tiles[4], @tiles[5], @tiles[6],
      @tiles[44], @tiles[45], @tiles[46],
      @tiles[84], @tiles[88], @tiles[92],
      @tiles[108], @tiles[109]
    ]

    @current_player.instance_variable_set(:@hands, agari_hands)
    round_wind = '1z' # 東場
    mask = StateBuilder.build_tsumo_action_mask(@current_player, round_wind)
    expected = [0] * 21 + [1] * 2
    assert_equal expected, mask

    # 111222萬 333筒 456索 東中
    normal_hands = [
      @tiles[0], @tiles[1], @tiles[2],
      @tiles[4], @tiles[5], @tiles[6],
      @tiles[44], @tiles[45], @tiles[46],
      @tiles[84], @tiles[88], @tiles[92],
      @tiles[108], @tiles[132]
    ]

    @current_player.instance_variable_set(:@hands, normal_hands)
    mask = StateBuilder.build_tsumo_action_mask(@current_player, round_wind)
    expected = [0] * 22 + [1]
    assert_equal expected, mask
  end

  def test_build_discard_action_mask
    # 111222萬 333筒 456索 東中
    hands = [
      @tiles[0], @tiles[1], @tiles[2],
      @tiles[4], @tiles[5], @tiles[6],
      @tiles[44], @tiles[45], @tiles[46],
      @tiles[84], @tiles[88], @tiles[92],
      @tiles[108], @tiles[132]
    ]

    @current_player.instance_variable_set(:@hands, hands)
    mask = StateBuilder.build_discard_action_mask(@current_player)
    expected = [1] * 14 + [0] * 9
    assert_equal expected, mask

    # 12萬
    tanki_hands = [@tiles[0], @tiles[4]]
    @current_player.instance_variable_set(:@hands, tanki_hands)
    mask = StateBuilder.build_discard_action_mask(@current_player)
    expected = [1] * 2 + [0] * 21
    assert_equal expected, mask
  end
end
