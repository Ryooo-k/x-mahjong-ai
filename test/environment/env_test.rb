# frozen_string_literal: true
require 'debug'
require 'test/unit'
require_relative '../../src/environment/env'
require_relative '../util/file_loader'

class EnvTest < Test::Unit::TestCase
  TILES = Array.new(136) { |id| Tile.new(id) }.freeze

  class DummyPlayer
    attr_reader :hands, :hand_histories, :called_tile_table, :rivers, :score

    def initialize
      # 123456萬 123筒 78索 東 南
      @hands = [
        TILES[0], TILES[4], TILES[8], TILES[12], TILES[16], TILES[20],
        TILES[36], TILES[40], TILES[44],
        TILES[96], TILES[100],
        TILES[108], TILES[113]
      ]
      @hand_histories = [@hands.dup]
      @called_tile_table = []
      @rivers = []
      @score = 25_000
    end

    def draw(tile)
      @hands << tile
    end

    def discard(tile)
      @hands.delete(tile)
      @hand_histories << @hands.dup
    end

    def sorted_hands
      @hands.sort_by(&:id)
    end
  end

  def setup
    @all_tiles = Array.new(136) { |id| Tile.new(id) }
    parameter = FileLoader.load_parameter
    @env = Env.new(parameter['table'], parameter['player'])
  end

  def test_player_draw
    top_tile = @env.table.top_tile
    before_draw_count = @env.table.draw_count
    @env.player_draw
    assert_equal top_tile, @env.current_player.hands.last
    assert_equal before_draw_count + 1, @env.table.draw_count
  end

  def test_can_not_player_draw_when_game_over
    122.times { |_| @env.player_draw }
    result = @env.player_draw
    assert_equal nil, result
  end

  def test_rotate_turn
    current_player = @env.current_player.dup
    other_players = @env.other_players.dup
    @env.rotate_turn
    assert_not_equal current_player, @env.current_player
    assert_not_equal other_players, @env.other_players
  end

  def test_update_triggered_by_game_over
    70.times do |_|
      @env.player_draw
      target_tile = @env.current_player.hands.first
      @env.current_player.discard(target_tile)
    end # ゲーム終了までツモる

    action = 0
    expected_tile = @env.current_player.sorted_hands[action]
    _, reward, done, discarded_tile  = @env.step(action)
    assert_equal -100, reward
    assert_equal true, done
    assert_equal expected_tile, discarded_tile
  end

  def test_update_triggered_by_shanten_decrease
    @env.instance_variable_set(:@current_player, DummyPlayer.new)
    @env.current_player.draw(TILES[109]) # 東を引いて聴牌形にする
    _, reward, done, discarded_tile = @env.step(13) # 南(index=13)を捨て聴牌にする
    assert_equal reward, 50 # 向聴数が減った時の報酬と一致する
    assert_equal done, false
    assert_equal discarded_tile, TILES[113]
  end

  def test_update_triggered_by_agari
    @env.instance_variable_set(:@current_player, DummyPlayer.new)
    @env.current_player.draw(TILES[109]) # 東を引いて聴牌形にする
    @env.step(13) # 南(index=13)を捨て聴牌にする
    @env.current_player.draw(TILES[104]) # 9索を引いて和了にする
    _, reward, done, discarded_tile = @env.step(0)
    assert_equal reward, 100 # 和了時の報酬と一致する
    assert_equal done, true
    assert_equal discarded_tile, nil
  end
end
