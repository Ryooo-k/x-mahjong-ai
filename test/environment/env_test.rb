# frozen_string_literal: true

require 'test/unit'
require 'mocha/test_unit'
require_relative '../../src/environment/env'
require_relative '../util/file_loader'

class EnvTest < Test::Unit::TestCase
  ACTION_NUMBER = 1

  def setup
    @tiles = Array.new(136) { |id| Tile.new(id) }
    config = FileLoader.load_parameter
    @env = Env.new(config['table'], config['agent'])
  end

  # env変更予定のため、テストは一時的にコメントアウト

  # def test_step_when_host_player_mangan_tsumo
  #   # 123456789萬 789索 東
  #   # 一気通貫、ツモ、ドラドラ
  #   # 親の満貫（12_000点）
  #   hands = [
  #     @tiles[0], @tiles[4], @tiles[8],
  #     @tiles[12], @tiles[16], @tiles[20],
  #     @tiles[24], @tiles[28], @tiles[32],
  #     @tiles[96], @tiles[100], @tiles[104],
  #     @tiles[108]
  #   ]
  #   live_walls = [@tiles[109]] * 122 # 東を必ずツモるようにする
  #   open_dora_indicators = [@tiles[120]] # 東がドラとなるようにする

  #   @env.current_player.instance_variable_set(:@hands, hands)
  #   @env.table.tile_wall.instance_variable_set(:@live_walls, live_walls)
  #   @env.table.tile_wall.instance_variable_set(:@open_dora_indicators, open_dora_indicators)
  #   @env.stubs(:get_tsumo_action).returns(ACTION_NUMBER)
  #   @env.step

  #   assert_equal 37_000, @env.current_player.score
  #   assert_equal 1, @env.current_player.rank
  #   @env.other_players.each_with_index do |player, i|
  #     rank = i + 2
  #     assert_equal 21_000, player.score
  #     assert_equal rank, player.rank
  #   end
  #   assert_equal true, @env.round_over?
  # end

  # def test_step_when_other_player_mangan_ron
  #   # 12345678萬 22筒 789索
  #   # 平和、一気通貫、ドラドラ
  #   # 子の満貫（8_000点）
  #   hands = [
  #     @tiles[0], @tiles[4], @tiles[8],
  #     @tiles[12], @tiles[16], @tiles[20],
  #     @tiles[24], @tiles[28],
  #     @tiles[40], @tiles[41],
  #     @tiles[96], @tiles[100], @tiles[104],
  #   ]
  #   open_dora_indicators = [@tiles[36]] # 2筒がドラとなるようにする
  #   ron_player = @env.other_players[0]
  #   other_players = @env.other_players.reject { |player| player == ron_player }
  #   ron_player.instance_variable_set(:@hands, hands)
  #   @env.table.tile_wall.instance_variable_set(:@open_dora_indicators, open_dora_indicators)
  #   @env.stubs(:handle_discard_action).returns([0, @tiles[32]]) # 9萬を捨てる
  #   @env.stubs(:get_tsumo_action).returns(false)
  #   @env.stubs(:get_ron_action).returns([ACTION_NUMBER, ron_player])
  #   @env.step

  #   assert_equal 33_000, ron_player.score
  #   assert_equal 1, ron_player.rank
  #   assert_equal 17_000, @env.current_player.score
  #   assert_equal 4, @env.current_player.rank

  #   other_players.each_with_index do |player, i|
  #     rank = i + 2
  #     assert_equal 25_000, player.score
  #     assert_equal rank, player.rank
  #   end
  #   assert_equal true, @env.round_over?
  # end
end
