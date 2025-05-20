# frozen_string_literal: true

require 'test/unit'
require_relative '../../util/file_loader'
require_relative '../../../src/domain/logic/hand_evaluator'
require_relative '../../../src/domain/tile'
require_relative '../../../src/domain/table'
require_relative '../../../src/util/encoder'

class HandEvaluatorTest < Test::Unit::TestCase
  def setup
    @evaluator = Domain::Logic::HandEvaluator
    @tiles = Array.new(135) { |id| Tile.new(id) }
  end

  def test_count_outs_when_tenpai_normal_hands
    # 通常手(聴牌): 111222萬 333筒 45索 東東
    # 向聴数：0
    # 有効牌：2種8枚 (36索)
    hands = [
      @tiles[0], @tiles[1], @tiles[2],
      @tiles[4], @tiles[5], @tiles[6],
      @tiles[44], @tiles[45], @tiles[46],
      @tiles[84], @tiles[88],
      @tiles[108], @tiles[109]
    ]

    outs = @evaluator.count_outs(hands)
    normal_outs = outs[:normal]
    outs_kind = normal_outs.map(&:code).uniq.size
    outs_count = normal_outs.size
    outs_names = normal_outs.map(&:name).uniq
    assert_equal 2, outs_kind
    assert_equal 8, outs_count
    assert_equal %w[3索 6索], outs_names
  end

  def test_count_outs_when_normal_hands
    # 通常手(ノーテン): 128萬 555889筒 357索 東
    # 向聴数：3
    # 有効牌：19種68枚 (36789萬 6789筒 123456789索 東)
    hands = [
      @tiles[0], @tiles[4], @tiles[28],
      @tiles[52], @tiles[53], @tiles[54],
      @tiles[64], @tiles[68], @tiles[69],
      @tiles[80], @tiles[88], @tiles[96],
      @tiles[108]
    ]

    outs = @evaluator.count_outs(hands)
    normal_outs = outs[:normal]
    outs_kind = normal_outs.map(&:code).uniq.size
    outs_count = normal_outs.size
    outs_names = normal_outs.map(&:name).uniq
    assert_equal 19, outs_kind
    assert_equal 68, outs_count
    assert_equal %w[3萬 6萬 7萬 8萬 9萬 6筒 7筒 8筒 9筒 1索 2索 3索 4索 5索 6索 7索 8索 9索 東], outs_names
  end

  def test_count_outs_when_tenpai_chiitoitsu_hands
    # 七対子(聴牌)： 112288萬 3355筒 44索 東
    # 向聴数：0
    # 有効牌：1種3枚 (東)
    hands = [
      @tiles[0], @tiles[1],
      @tiles[4], @tiles[5],
      @tiles[28], @tiles[28],
      @tiles[44], @tiles[45],
      @tiles[52], @tiles[53],
      @tiles[84], @tiles[84],
      @tiles[108]
    ]

    outs = @evaluator.count_outs(hands)
    chiitoitsu_outs = outs[:chiitoitsu]
    outs_kind = chiitoitsu_outs.map(&:code).uniq.size
    outs_count = chiitoitsu_outs.size
    outs_names = chiitoitsu_outs.map(&:name).uniq
    assert_equal 1, outs_kind
    assert_equal 3, outs_count
    assert_equal ['東'], outs_names
  end

  def test_count_outs_when_chiitoitsu_hands
    # 七対子(ノーテン)： 112288萬 3355筒 4索 東 白
    # 向聴数：1
    # 有効牌：3種9枚 (4索 東 白)
    hands = [
      @tiles[0], @tiles[1],
      @tiles[4], @tiles[5],
      @tiles[28], @tiles[28],
      @tiles[44], @tiles[45],
      @tiles[52], @tiles[53],
      @tiles[84],
      @tiles[108],
      @tiles[124]
    ]

    outs = @evaluator.count_outs(hands)
    chiitoitsu_outs = outs[:chiitoitsu]
    outs_kind = chiitoitsu_outs.map(&:code).uniq.size
    outs_count = chiitoitsu_outs.size
    outs_names = chiitoitsu_outs.map(&:name).uniq
    assert_equal 3, outs_kind
    assert_equal 9, outs_count
    assert_equal %w[4索 東 白], outs_names
  end

  def test_count_outs_when_tenpai_kokushi_hands_without_head
    # 国士無双（頭なし聴牌）： 19萬 19筒 19索 東 南 西 北 白 發 中
    # 向聴数：0
    # 有効牌：13種39枚 (19萬 19筒 19索 東 南 西 北 白 發 中)
    hands = [
      @tiles[0], @tiles[32],
      @tiles[36], @tiles[68],
      @tiles[72], @tiles[104],
      @tiles[108], @tiles[112], @tiles[116], @tiles[120],
      @tiles[124], @tiles[128], @tiles[132]
    ]

    outs = @evaluator.count_outs(hands)
    kokushi_outs = outs[:kokushi]
    outs_kind = kokushi_outs.map(&:code).uniq.size
    outs_count = kokushi_outs.size
    outs_names = kokushi_outs.map(&:name).uniq
    assert_equal 13, outs_kind
    assert_equal 39, outs_count
    assert_equal %w[1萬 9萬 1筒 9筒 1索 9索 東 南 西 北 白 發 中], outs_names
  end

  def test_count_outs_when_tenpai_kokushi_hands_with_head
    # 国士無双（頭あり聴牌）： 119萬 19筒 19索 東 南 西 北 白 發
    # 向聴数：0
    # 有効牌：1種4枚 (中)
    hands = [
      @tiles[0], @tiles[0], @tiles[32],
      @tiles[36], @tiles[68],
      @tiles[72], @tiles[104],
      @tiles[108], @tiles[112], @tiles[116], @tiles[120],
      @tiles[124], @tiles[128]
    ]

    outs = @evaluator.count_outs(hands)
    kokushi_outs = outs[:kokushi]
    outs_kind = kokushi_outs.map(&:code).uniq.size
    outs_count = kokushi_outs.size
    outs_names = kokushi_outs.map(&:name).uniq
    assert_equal 1, outs_kind
    assert_equal 4, outs_count
    assert_equal ['中'], outs_names
  end

  def test_count_outs_when_kokushi_hands_without_head
    # 国士無双（頭なしノーテン）： 159萬 159筒 159索 東 南 西 北
    # 向聴数：3
    # 有効牌：13種42枚 (19萬 19筒 19索 東 南 西 北 白 發 中)
    hands = [
      @tiles[0], @tiles[16], @tiles[32],
      @tiles[36], @tiles[52], @tiles[68],
      @tiles[72], @tiles[88], @tiles[104],
      @tiles[108], @tiles[112], @tiles[116], @tiles[120]
    ]

    outs = @evaluator.count_outs(hands)
    kokushi_outs = outs[:kokushi]
    outs_kind = kokushi_outs.map(&:code).uniq.size
    outs_count = kokushi_outs.size
    outs_names = kokushi_outs.map(&:name).uniq
    assert_equal 13, outs_kind
    assert_equal 42, outs_count
    assert_equal %w[1萬 9萬 1筒 9筒 1索 9索 東 南 西 北 白 發 中], outs_names
  end

  def test_count_outs_when_kokushi_hands_with_head
    # 国士無双（頭ありノーテン）： 119萬 159筒 19索 東 南 西 白 發
    # 向聴数：1
    # 有効牌：2種8枚 (北 中)
    hands = [
      @tiles[0], @tiles[0], @tiles[32],
      @tiles[36], @tiles[52], @tiles[68],
      @tiles[72], @tiles[104],
      @tiles[108], @tiles[112], @tiles[116],
      @tiles[124], @tiles[128]
    ]

    outs = @evaluator.count_outs(hands)
    kokushi_outs = outs[:kokushi]
    outs_kind = kokushi_outs.map(&:code).uniq.size
    outs_count = kokushi_outs.size
    outs_names = kokushi_outs.map(&:name).uniq
    assert_equal 2, outs_kind
    assert_equal 8, outs_count
    assert_equal %w[北 中], outs_names
  end

  def test_calculate_minimum_shanten_when_tenpai_normal_hands
    # 通常手(聴牌): 111222萬 333筒 45索 東東
    # 向聴数：0
    hands = [
      @tiles[0], @tiles[1], @tiles[2],
      @tiles[4], @tiles[5], @tiles[6],
      @tiles[44], @tiles[45], @tiles[46],
      @tiles[84], @tiles[88],
      @tiles[108], @tiles[109]
    ]

    shanten = @evaluator.calculate_minimum_shanten(hands)
    assert_equal 0, shanten
  end

  def test_calculate_minimum_shanten_when_normal_hands
    # 通常手(ノーテン): 128萬 555889筒 357索 東
    # 向聴数：3
    hands = [
      @tiles[0], @tiles[4], @tiles[28],
      @tiles[52], @tiles[53], @tiles[54],
      @tiles[64], @tiles[68], @tiles[69],
      @tiles[80], @tiles[88], @tiles[96],
      @tiles[108]
    ]

    shanten = @evaluator.calculate_minimum_shanten(hands)
    assert_equal 3, shanten
  end

  def test_calculate_minimum_shanten_when_tenpai_chiitoitsu_hands
    # 七対子(聴牌)： 112288萬 3355筒 44索 東
    # 向聴数：0
    hands = [
      @tiles[0], @tiles[1],
      @tiles[4], @tiles[5],
      @tiles[28], @tiles[28],
      @tiles[44], @tiles[45],
      @tiles[52], @tiles[53],
      @tiles[84], @tiles[84],
      @tiles[108]
    ]

    shanten = @evaluator.calculate_minimum_shanten(hands)
    assert_equal 0, shanten
  end

  def test_calculate_minimum_shanten_when_chiitoitsu_hands
    # 七対子(ノーテン)： 112288萬 3355筒 4索 東 白
    # 向聴数：1
    hands = [
      @tiles[0], @tiles[1],
      @tiles[4], @tiles[5],
      @tiles[28], @tiles[28],
      @tiles[44], @tiles[45],
      @tiles[52], @tiles[53],
      @tiles[84],
      @tiles[108],
      @tiles[124]
    ]

    shanten = @evaluator.calculate_minimum_shanten(hands)
    assert_equal 1, shanten
  end

  def test_calculate_minimum_shanten_when_tenpai_kokushi_hands_without_head
    # 国士無双（頭なし聴牌）： 19萬 19筒 19索 東 南 西 北 白 發 中
    # 向聴数：0
    hands = [
      @tiles[0], @tiles[32],
      @tiles[36], @tiles[68],
      @tiles[72], @tiles[104],
      @tiles[108], @tiles[112], @tiles[116], @tiles[120],
      @tiles[124], @tiles[128], @tiles[132]
    ]

    shanten = @evaluator.calculate_minimum_shanten(hands)
    assert_equal 0, shanten
  end

  def test_calculate_minimum_shanten_when_tenpai_kokushi_hands_with_head
    # 国士無双（頭あり聴牌）： 119萬 19筒 19索 東 南 西 北 白 發
    # 向聴数：0
    hands = [
      @tiles[0], @tiles[0], @tiles[32],
      @tiles[36], @tiles[68],
      @tiles[72], @tiles[104],
      @tiles[108], @tiles[112], @tiles[116], @tiles[120],
      @tiles[124], @tiles[128]
    ]

    shanten = @evaluator.calculate_minimum_shanten(hands)
    assert_equal 0, shanten
  end

  def test_calculate_minimum_shanten_when_kokushi_hands_without_head
    # 国士無双（頭なしノーテン）： 159萬 159筒 159索 東 南 西 北
    # 向聴数：3
    hands = [
      @tiles[0], @tiles[16], @tiles[32],
      @tiles[36], @tiles[52], @tiles[68],
      @tiles[72], @tiles[88], @tiles[104],
      @tiles[108], @tiles[112], @tiles[116], @tiles[120]
    ]

    shanten = @evaluator.calculate_minimum_shanten(hands)
    assert_equal 3, shanten
  end

  def test_calculate_minimum_shanten_when_kokushi_hands_with_head
    # 国士無双（頭ありノーテン）： 119萬 159筒 19索 東 南 西 白 發
    # 向聴数：1
    hands = [
      @tiles[0], @tiles[0], @tiles[32],
      @tiles[36], @tiles[52], @tiles[68],
      @tiles[72], @tiles[104],
      @tiles[108], @tiles[112], @tiles[116],
      @tiles[124], @tiles[128]
    ]

    shanten = @evaluator.calculate_minimum_shanten(hands)
    assert_equal 1, shanten
  end

  def test_calculate_shanten_when_normal_hands
    # 通常手(ノーテン): 128萬 555889筒 357索 東
    # 向聴数：3
    hands = [
      @tiles[0], @tiles[4], @tiles[28],
      @tiles[52], @tiles[53], @tiles[54],
      @tiles[64], @tiles[68], @tiles[69],
      @tiles[80], @tiles[88], @tiles[96],
      @tiles[108]
    ]

    shanten = @evaluator.calculate_shanten(hands)
    assert_equal 3, shanten[:normal]
    assert_equal 4, shanten[:chiitoitsu]
    assert_equal 9, shanten[:kokushi]
  end

  def test_calculate_shanten_when_chiitoitsu_hands
    # 七対子(ノーテン)： 112288萬 3355筒 4索 東 白
    # 向聴数：1
    hands = [
      @tiles[0], @tiles[1],
      @tiles[4], @tiles[5],
      @tiles[28], @tiles[28],
      @tiles[44], @tiles[45],
      @tiles[52], @tiles[53],
      @tiles[84],
      @tiles[108],
      @tiles[124]
    ]

    shanten = @evaluator.calculate_shanten(hands)
    assert_equal 3, shanten[:normal]
    assert_equal 1, shanten[:chiitoitsu]
    assert_equal 9, shanten[:kokushi]
  end

  def test_calculate_shanten_when_kokushi_hands
    # 国士無双（頭なしノーテン）： 159萬 159筒 159索 東 南 西 北
    # 向聴数：3
    hands = [
      @tiles[0], @tiles[16], @tiles[32],
      @tiles[36], @tiles[52], @tiles[68],
      @tiles[72], @tiles[88], @tiles[104],
      @tiles[108], @tiles[112], @tiles[116], @tiles[120]
    ]

    shanten = @evaluator.calculate_shanten(hands)
    assert_equal 8, shanten[:normal]
    assert_equal 6, shanten[:chiitoitsu]
    assert_equal 3, shanten[:kokushi]
  end

  def test_agari?
    # 和了手: 111222萬 333筒 444索 東東
    # 向聴数：-1
    agari_hands = [
      @tiles[0], @tiles[1], @tiles[2],
      @tiles[4], @tiles[5], @tiles[6],
      @tiles[44], @tiles[45], @tiles[46],
      @tiles[84], @tiles[85], @tiles[86],
      @tiles[108], @tiles[109]
    ]

    assert_equal true, @evaluator.agari?(agari_hands)
  end

  def test_tenpai?
    # 通常手(聴牌): 111222萬 333筒 45索 東東
    tenpai_hands = [
      @tiles[0], @tiles[1], @tiles[2],
      @tiles[4], @tiles[5], @tiles[6],
      @tiles[44], @tiles[45], @tiles[46],
      @tiles[84], @tiles[88],
      @tiles[108], @tiles[109]
    ]

    # 通常手(ノーテン): 128萬 555889筒 357索 東
    not_tenpai_hands = [
      @tiles[0], @tiles[4], @tiles[28],
      @tiles[52], @tiles[53], @tiles[54],
      @tiles[64], @tiles[68], @tiles[69],
      @tiles[80], @tiles[88], @tiles[96],
      @tiles[108]
    ]

    assert_equal true, @evaluator.tenpai?(tenpai_hands)
    assert_equal false, @evaluator.tenpai?(not_tenpai_hands)
  end

  def test_evaluate_yaku_when_host_haneman_point
    # 123456789萬 23筒 11索
    # 和了牌：14筒
    hands = [
      @tiles[0], @tiles[4], @tiles[8],
      @tiles[12], @tiles[16], @tiles[20],
      @tiles[24], @tiles[28], @tiles[32],
      @tiles[40], @tiles[44],
      @tiles[72], @tiles[73]
    ]
    melds_list = []
    winning_tile = @tiles[48] # 4筒
    round_wind = '1z' # 東のnumber+suit
    player_wind = '1z' # 親番
    is_tsumo = true
    open_dora_indicators = [@tiles[1]] # 1萬がドラ表示牌
    blind_dora_indicators = [@tiles[13]] # 4萬が裏ドラ表示牌
    is_riichi = true
    honba = 1
    result = @evaluator.evaluate_yaku(hands:, melds_list:, winning_tile:, round_wind:, player_wind:, is_tsumo:, open_dora_indicators:, is_riichi:, blind_dora_indicators:, honba:)

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

  def test_evaluate_yaku_when_child_mangan_point
    # 111222萬 東
    # 和了牌：東
    hands = [
      @tiles[0], @tiles[1], @tiles[2],
      @tiles[4], @tiles[5], @tiles[6],
      @tiles[108]
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
    is_riichi = false
    honba = 0
    result = @evaluator.evaluate_yaku(hands:, melds_list:, winning_tile:, round_wind:, player_wind:, is_tsumo:, open_dora_indicators:, is_riichi:, blind_dora_indicators:, honba:)

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

  def test_has_yaku_return_false_without_yaku
    # 役無し聴牌: 12379萬 333筒 456索 東東
    hands = [
      @tiles[0], @tiles[4], @tiles[8],
      @tiles[24],@tiles[32],
      @tiles[44], @tiles[45], @tiles[46],
      @tiles[84], @tiles[88], @tiles[92],
      @tiles[108], @tiles[109]
    ]
    melds_list = []
    target_tile = @tiles[28] # 8萬
    round_wind = '1z' # 東のnumber+suit
    player_wind = '1z'
    is_tsumo = false
    is_riichi = false
    result = @evaluator.has_yaku?(hands:, melds_list:, target_tile:, round_wind:, player_wind:, is_tsumo:, is_riichi:)

    assert_equal false, result
  end

  def test_has_yaku_return_yaku_when_player_have_yaku
    # 役あり聴牌: 12379萬 33筒 456索 東東東
    hands = [
      @tiles[0], @tiles[4], @tiles[8],
      @tiles[24],@tiles[32],
      @tiles[44], @tiles[45],
      @tiles[84], @tiles[88], @tiles[92],
      @tiles[108], @tiles[109], @tiles[110]
    ]
    melds_list = []
    target_tile = @tiles[28] # 8萬
    round_wind = '1z' # 東のnumber+suit
    player_wind = '1z'
    is_tsumo = false
    is_riichi = false
    yaku = @evaluator.has_yaku?(hands:, melds_list:, target_tile:, round_wind:, player_wind:, is_tsumo:, is_riichi:)

    assert_equal(
      [
        {"han"=>1, "name"=>"自風牌"},
        {"han"=>1, "name"=>"場風牌"}
      ], yaku)
  end

  def test_calculate_tsumo_agari_point_when_host_mangan_agari
    config = FileLoader.load_parameter
    table = Table.new(config['table'], config['player'])

    # 和了手: 111222萬 345筒 456索 東東
    # ツモ牌：東（hands.last）
    hands = [
      @tiles[0], @tiles[1], @tiles[2],
      @tiles[4], @tiles[5], @tiles[6],
      @tiles[44], @tiles[48], @tiles[52],
      @tiles[84], @tiles[88], @tiles[92],
      @tiles[108], @tiles[109]
    ]

    player = table.host
    player.instance_variable_set(:@hands, hands)
    player.instance_variable_set(:@wind, '1z')
    table.tile_wall.instance_variable_set(:@open_dora_indicators, [@tiles[32]]) # 1萬がドラ

    received_point, paid_by_host, paid_by_child = @evaluator.calculate_tsumo_agari_point(player, table)
    assert_equal 12_000, received_point
    assert_equal 0, paid_by_host
    assert_equal -4_000, paid_by_child
  end

  def test_calculate_tsumo_agari_point_when_child_mangan_agari
    config = FileLoader.load_parameter
    table = Table.new(config['table'], config['player'])

    # 和了手: 111222萬 345筒 456索 東東
    # ツモ牌：東（hands.last）
    hands = [
      @tiles[0], @tiles[1], @tiles[2],
      @tiles[4], @tiles[5], @tiles[6],
      @tiles[44], @tiles[48], @tiles[52],
      @tiles[84], @tiles[88], @tiles[92],
      @tiles[108], @tiles[109]
    ]

    player = table.children[0]
    player.instance_variable_set(:@hands, hands)
    player.instance_variable_set(:@wind, '2z')
    table.tile_wall.instance_variable_set(:@open_dora_indicators, [@tiles[32]]) # 1萬がドラ

    received_point, paid_by_host, paid_by_child = @evaluator.calculate_tsumo_agari_point(player, table)
    assert_equal 8_000, received_point
    assert_equal -4_000, paid_by_host
    assert_equal -2_000, paid_by_child
  end

  def test_calculate_tsumo_agari_point_when_host_chombo
    config = FileLoader.load_parameter
    table = Table.new(config['table'], config['player'])

    # 和了できない手: 111222萬 345筒 456索 東中
    hands = [
      @tiles[0], @tiles[1], @tiles[2],
      @tiles[4], @tiles[5], @tiles[6],
      @tiles[44], @tiles[48], @tiles[52],
      @tiles[84], @tiles[88], @tiles[92],
      @tiles[108], @tiles[132]
    ]

    player = table.host
    player.instance_variable_set(:@hands, hands)
    player.instance_variable_set(:@wind, '1z')
    table.tile_wall.instance_variable_set(:@open_dora_indicators, [@tiles[32]])

    received_point, paid_by_host, paid_by_child = @evaluator.calculate_tsumo_agari_point(player, table)
    assert_equal -12_000, received_point
    assert_equal 0, paid_by_host
    assert_equal 4_000, paid_by_child
  end

  def test_calculate_tsumo_agari_point_when_child_chombo
    config = FileLoader.load_parameter
    table = Table.new(config['table'], config['player'])

    # 和了できない手: 111222萬 345筒 456索 東中
    hands = [
      @tiles[0], @tiles[1], @tiles[2],
      @tiles[4], @tiles[5], @tiles[6],
      @tiles[44], @tiles[48], @tiles[52],
      @tiles[84], @tiles[88], @tiles[92],
      @tiles[108], @tiles[132]
    ]

    player = table.children[0]
    player.instance_variable_set(:@hands, hands)
    player.instance_variable_set(:@wind, '1z')
    table.tile_wall.instance_variable_set(:@open_dora_indicators, [@tiles[32]])

    received_point, paid_by_host, paid_by_child = @evaluator.calculate_tsumo_agari_point(player, table)
    assert_equal -8_000, received_point
    assert_equal 4_000, paid_by_host
    assert_equal 2_000, paid_by_child
  end

  def test_calculate_ron_agari_point
    config = FileLoader.load_parameter
    table = Table.new(config['table'], config['player'])

    # 和了手: 111222萬 333筒 444索 東東
    # 和了牌：4索（hands.last）
    # 対々和、三暗刻、ドラ３
    hands = [
      @tiles[0], @tiles[1], @tiles[2],
      @tiles[4], @tiles[5], @tiles[6],
      @tiles[44], @tiles[45], @tiles[46],
      @tiles[84], @tiles[85],
      @tiles[108], @tiles[109],
      @tiles[86]
    ]

    player = table.host
    player.instance_variable_set(:@hands, hands)
    player.instance_variable_set(:@wind, '1z')
    table.tile_wall.instance_variable_set(:@open_dora_indicators, [@tiles[32]]) # 1萬がドラ

    point = @evaluator.calculate_ron_agari_point(player, table)
    assert_equal [18_000, 0, 0], point
  end

  def test_calculate_ron_agari_point_when_host_chombo
    config = FileLoader.load_parameter
    table = Table.new(config['table'], config['player'])

    # 和了できない手: 111222萬 333筒 44索 東東 中
    hands = [
      @tiles[0], @tiles[1], @tiles[2],
      @tiles[4], @tiles[5], @tiles[6],
      @tiles[44], @tiles[45], @tiles[46],
      @tiles[84], @tiles[85],
      @tiles[108], @tiles[109],
      @tiles[132]
    ]

    player = table.host
    player.instance_variable_set(:@hands, hands)
    player.instance_variable_set(:@wind, '1z')
    table.tile_wall.instance_variable_set(:@open_dora_indicators, [@tiles[32]])

    point = @evaluator.calculate_ron_agari_point(player, table)
    assert_equal [-12_000, 0, 4_000], point
  end

  def test_calculate_ron_agari_point_when_child_chombo
    config = FileLoader.load_parameter
    table = Table.new(config['table'], config['player'])

    # 和了できない手: 111222萬 333筒 44索 東東 中
    hands = [
      @tiles[0], @tiles[1], @tiles[2],
      @tiles[4], @tiles[5], @tiles[6],
      @tiles[44], @tiles[45], @tiles[46],
      @tiles[84], @tiles[85],
      @tiles[108], @tiles[109],
      @tiles[132]
    ]

    player = table.children[0]
    player.instance_variable_set(:@hands, hands)
    player.instance_variable_set(:@wind, '1z')
    table.tile_wall.instance_variable_set(:@open_dora_indicators, [@tiles[32]])

    point = @evaluator.calculate_ron_agari_point(player, table)
    assert_equal [-8_000, 4_000, 2_000], point
  end
end
