# frozen_string_literal: true

require 'test/unit'
require_relative '../src/environment/tile'

class TileTest < Test::Unit::TestCase
  def setup
    @manzu_1 = { code: 1, ids: (0..3).to_a, name: '1萬'}
    @manzu_5 = { code: 5, ids: (16..19).to_a, name: '5萬'}
    @east = { code: 31, ids: (108..111).to_a, name: '東' }
    @manzu_1_tile = Tile.new(@manzu_1[:ids][0])
    @red_tile = Tile.new(@manzu_5[:ids][0], is_red_dora: true)
  end

  def test_initialize_normal_tile
    initial_holder = nil
    initial_dora_count = 0

    assert_include(@manzu_1[:ids], @manzu_1_tile.id)
    assert_equal(@manzu_1[:code], @manzu_1_tile.code)
    assert_equal('1萬', @manzu_1_tile.name)
    assert_equal(initial_holder, @manzu_1_tile.holder)
    assert_equal(initial_dora_count, @manzu_1_tile.dora[:open][:count])
    assert_equal(initial_dora_count, @manzu_1_tile.dora[:blind][:count])
    assert_equal(initial_dora_count, @manzu_1_tile.dora[:red][:count])

    east_tile = Tile.new(@east[:ids][0])
    assert_include(@east[:ids], east_tile.id)
    assert_equal(@east[:code], east_tile.code)
    assert_equal('東', east_tile.name)
    assert_equal(initial_holder, east_tile.holder)
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

  def test_can_not_generate_tile_when_id_does_not_match
    noting_id = 1000
    assert_raise(ArgumentError) { Tile.new(noting_id) }
  end

  def test_red_dora_returns_true_for_red_tile
    assert_equal(true, @red_tile.red_dora?)
    assert_equal(false, @manzu_1_tile.red_dora?)
  end
end
