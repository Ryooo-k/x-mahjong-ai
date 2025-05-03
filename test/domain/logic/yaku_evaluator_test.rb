# frozen_string_literal: true

require 'test/unit'
require_relative '../../../src/domain/logic/yaku_evaluator'
require_relative '../../../src/domain/tile'

class YakuEvaluatorTest < Test::Unit::TestCase
  def setup
    @yaku_evaluator = Domain::Logic::YakuEvaluator
    @tiles = Array.new(135) { |id| Tile.new(id) }
  end

  def test_get_yaku_with_host_haneman_point
    # 123456789萬 234筒 11索
    hands = [
      @tiles[0], @tiles[4], @tiles[8],
      @tiles[12], @tiles[16], @tiles[20],
      @tiles[24], @tiles[28], @tiles[32],
      @tiles[40], @tiles[44], @tiles[48],
      @tiles[72], @tiles[73]
    ]

    melds_list = []
    winning_tile = @tiles[48] # 4筒
    round_wind = '1z' # 東のnumber+suit
    player_wind = '1z' # 親番
    is_tsumo = true
    open_dora_indicators = [@tiles[1]] # 1萬がドラ表示牌
    blind_dora_indicators = [@tiles[13]] # 4萬が裏ドラ表示牌
    is_reach = true
    honba = { count: 1 }

    result = @yaku_evaluator.get_yaku(
      hands,
      melds_list,
      winning_tile,
      round_wind,
      player_wind,
      is_tsumo,
      open_dora_indicators,
      is_reach,
      blind_dora_indicators,
      honba
    )

    assert_equal true, result['detail']['oya']
    assert_equal '跳満', result['scoreType']
    assert_equal 18_000, result['rawScore']
    assert_equal 18_300, result['score']
    assert_equal 6_100, result['pay']['ko']
    assert_equal nil, result['pay']['oya']
    assert_equal(
      [
        {"han"=>1, "name"=>"立直"},
        {"han"=>1, "name"=>"門前清自摸和"},
        {"han"=>2, "name"=>"一気通貫"},
        {"han"=>1, "name"=>"平和"},
        {"han"=>1, "name"=>"ドラ"},
        {"han"=>1, "name"=>"裏ドラ"}
      ], result['yaku'])
  end

  def test_get_yaku_with_child_mangan_point
    # 111222萬 東東
    hands = [
      @tiles[0], @tiles[1], @tiles[2],
      @tiles[4], @tiles[5], @tiles[6],
      @tiles[108], @tiles[109]
    ]

    # 555666萬
    melds_list = [
      {
        type: 'pong',
        tiles: [@tiles[16], @tiles[17], @tiles[18]]
      },
      {
        type: 'pong',
        tiles: [@tiles[20], @tiles[21], @tiles[22]]
      }
    ]
    winning_tile = @tiles[109] # 東
    round_wind = '1z' # 東のnumber+suit
    player_wind = '2z'
    is_tsumo = true
    open_dora_indicators = [@tiles[110]] # 東がドラ表示牌
    blind_dora_indicators = [@tiles[111]] # 東が裏ドラ表示牌
    is_reach = false
    honba = { count: 0 }

    result = @yaku_evaluator.get_yaku(
      hands,
      melds_list,
      winning_tile,
      round_wind,
      player_wind,
      is_tsumo,
      open_dora_indicators,
      is_reach,
      blind_dora_indicators,
      honba
    )

    assert_equal false, result['detail']['oya']
    assert_equal '満貫', result['scoreType']
    assert_equal 8_000, result['rawScore']
    assert_equal 8_000, result['score']
    assert_equal 2_000, result['pay']['ko']
    assert_equal 4_000, result['pay']['oya']
    assert_equal(
      [
        {"han"=>2, "name"=>"混一色"},
        {"han"=>2, "name"=>"対々和"}
      ], result['yaku'])
  end
end
