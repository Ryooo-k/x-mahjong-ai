# frozen_string_literal: true

require 'test/unit'
require_relative '../src/environment/tile'

class TileTest < Test::Unit::TestCase
  def setup
    @manzu_1 = { code: 0, ids: (0..3).to_a, name: '1萬'}
    @manzu_5 = { code: 4, ids: (16..19).to_a, name: '5萬'}
    @east = { code: 27, ids: (108..111).to_a, name: '東' }
    @manzu_1_tile = Tile.new(@manzu_1[:ids][0], @manzu_1[:code])
    @red_tile = Tile.new(@manzu_5[:ids][0], @manzu_5[:code], true)
  end

  def test_initialize_normal_tile
    initial_position = {}
    initial_action = { type: nil, from: nil, to: nil, order: nil }
    initial_dora_count = 0

    assert_include(@manzu_1[:ids], @manzu_1_tile.id)
    assert_equal(@manzu_1[:code], @manzu_1_tile.code)
    assert_equal('1萬', @manzu_1_tile.name)
    assert_equal(initial_position, @manzu_1_tile.position)
    assert_equal(initial_action, @manzu_1_tile.action)
    assert_equal(initial_dora_count, @manzu_1_tile.dora[:open][:count])
    assert_equal(initial_dora_count, @manzu_1_tile.dora[:blind][:count])
    assert_equal(initial_dora_count, @manzu_1_tile.dora[:red][:count])

    east_tile = Tile.new(@east[:ids][0], @east[:code])
    assert_include(@east[:ids], east_tile.id)
    assert_equal(@east[:code], east_tile.code)
    assert_equal('東', east_tile.name)
    assert_equal(initial_position, east_tile.position)
    assert_equal(initial_action, east_tile.action)
    assert_equal(initial_dora_count, east_tile.dora[:open][:count])
    assert_equal(initial_dora_count, east_tile.dora[:blind][:count])
    assert_equal(initial_dora_count, east_tile.dora[:red][:count])
  end

  def test_initialize_red_tile
    expected = {
      open_dora_count: 0,
      blind_dora_count: 0,
      red_dora_count: 1
    }
    assert_equal(expected[:open_dora_count], @red_tile.dora[:open][:count])
    assert_equal(expected[:blind_dora_count], @red_tile.dora[:blind][:count])
    assert_equal(expected[:red_dora_count], @red_tile.dora[:red][:count])
  end

  def test_can_not_generate_tile_when_id_does_not_match_code
    manzu_1_id = @manzu_1[:ids].sample
    manzu_5_code = @manzu_5[:code]
    assert_raise(ArgumentError) { Tile.new(manzu_1_id, manzu_5_code) }
  end

  def test_red_dora_returns_true_for_red_tile
    assert_equal(true, @red_tile.red_dora?)
    assert_equal(false, @manzu_1_tile.red_dora?)
  end

  def test_update_position_correctly_when_changed
    @manzu_1_tile.change_position(:live_wall)
    expected = { code: 0, name: '牌山' }
    assert_equal(expected[:code], @manzu_1_tile.position[:code])
    assert_equal(expected[:name], @manzu_1_tile.position[:name])

    @manzu_1_tile.change_position(:hand)
    expected = { code: 2, name: '手牌' }
    assert_equal(expected[:code], @manzu_1_tile.position[:code])
    assert_equal(expected[:name], @manzu_1_tile.position[:name])

    assert_raise(ArgumentError) { @manzu_1_tile.change_position(:nothing) }
  end

  def test_update_action_correctly_when_record
    player_id_0 = 0
    player_id_1 = 1
    order = 100
    @manzu_1_tile.record_action(type: :pong, from: player_id_0, to: player_id_1, order:)
    expected = {
      code: 0,
      name: 'ポン',
      from: player_id_0,
      to: player_id_1,
      order:
    }
    assert_equal(expected[:code], @manzu_1_tile.action[:code])
    assert_equal(expected[:name], @manzu_1_tile.action[:name])
    assert_equal(expected[:from], @manzu_1_tile.action[:from])
    assert_equal(expected[:to], @manzu_1_tile.action[:to])
    assert_equal(expected[:order], @manzu_1_tile.action[:order])
  end

  def test_can_not_change_action_when_already_set
    player_id_0 = 0
    player_id_1 = 1
    order = 100
    @manzu_1_tile.record_action(type: :pong, from: player_id_0, to: player_id_1, order:)
    assert_raise(RuntimeError) { @manzu_1_tile.record_action(type: :chow, from: player_id_0, to: player_id_1, order:) }
  end
end
