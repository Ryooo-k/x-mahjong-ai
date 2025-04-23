# frozen_string_literal: true

require 'test/unit'
require_relative '../../../src/domain/logic/hand_evaluator'
require_relative '../../../src/domain/tile'
require_relative '../../../src/util/encoder'

class HandEvaluatorTest < Test::Unit::TestCase
  def setup
    @evaluator = Domain::Logic::HandEvaluator
    tiles = (0..135).map { |id| Tile.new(id) }

    # 通常手(聴牌): 111222萬 333筒 45索 東東
    # 向聴数：0
    # 有効牌：2種8枚 (36索)
    @tenpai_normal_hands = [
      tiles[0], tiles[1], tiles[2],
      tiles[4], tiles[5], tiles[6],
      tiles[44], tiles[45], tiles[46],
      tiles[84], tiles[88],
      tiles[108], tiles[109]
    ]

    # 通常手(ノーテン): 128萬 555889筒 357索 東
    # 向聴数：3
    # 有効牌：19種68枚 (36789萬 6789筒 123456789索 東)
    @normal_hands = [
      tiles[0], tiles[4], tiles[28],
      tiles[52], tiles[53], tiles[54],
      tiles[64], tiles[68], tiles[69],
      tiles[80], tiles[88], tiles[96],
      tiles[108]
    ]

    # 七対子(聴牌)： 112288萬 3355筒 44索 東
    # 向聴数：0
    # 有効牌：1種3枚 (東)
    @tenpai_chiitoitsu_hands = [
      tiles[0], tiles[1],
      tiles[4], tiles[5],
      tiles[28], tiles[28],
      tiles[44], tiles[45],
      tiles[52], tiles[53],
      tiles[84], tiles[84],
      tiles[108]
    ]

    # 七対子(ノーテン)： 112288萬 3355筒 4索 東 白
    # 向聴数：1
    # 有効牌：3種9枚 (4索 東 白)
    @chiitoitsu_hands = [
      tiles[0], tiles[1],
      tiles[4], tiles[5],
      tiles[28], tiles[28],
      tiles[44], tiles[45],
      tiles[52], tiles[53],
      tiles[84],
      tiles[108],
      tiles[124]
    ]

    # 国士無双（頭なし聴牌）： 19萬 19筒 19索 東 南 西 北 白 發 中
    # 向聴数：0
    # 有効牌：13種39枚 (19萬 19筒 19索 東 南 西 北 白 發 中)
    @tenpai_kokushi_hands_without_head = [
      tiles[0], tiles[32],
      tiles[36], tiles[68],
      tiles[72], tiles[104],
      tiles[108], tiles[112], tiles[116], tiles[120],
      tiles[124], tiles[128], tiles[132]
    ]

    # 国士無双（頭あり聴牌）： 119萬 19筒 19索 東 南 西 北 白 發
    # 向聴数：0
    # 有効牌：1種4枚 (中)
    @tenpai_kokushi_hands_with_head = [
      tiles[0], tiles[0], tiles[32],
      tiles[36], tiles[68],
      tiles[72], tiles[104],
      tiles[108], tiles[112], tiles[116], tiles[120],
      tiles[124], tiles[128]
    ]

    # 国士無双（頭なしノーテン）： 159萬 159筒 159索 東 南 西 北
    # 向聴数：3
    # 有効牌：13種42枚 (19萬 19筒 19索 東 南 西 北 白 發 中)
    @kokushi_hands_without_head = [
      tiles[0], tiles[16], tiles[32],
      tiles[36], tiles[52], tiles[68],
      tiles[72], tiles[88], tiles[104],
      tiles[108], tiles[112], tiles[116], tiles[120]
    ]

    # 国士無双（頭ありノーテン）： 119萬 159筒 19索 東 南 西 白 發
    # 向聴数：1
    # 有効牌：2種8枚 (北 中)
    @kokushi_hands_with_head = [
      tiles[0], tiles[0], tiles[32],
      tiles[36], tiles[52], tiles[68],
      tiles[72], tiles[104],
      tiles[108], tiles[112], tiles[116],
      tiles[124], tiles[128]
    ]

    # 和了手: 111222萬 333筒 44索 東東
    # 向聴数：-1
    @agari_hands = [
      tiles[0], tiles[1], tiles[2],
      tiles[4], tiles[5], tiles[6],
      tiles[44], tiles[45], tiles[46],
      tiles[84], tiles[85], tiles[86],
      tiles[108], tiles[109]
    ]
  end

  def test_count_outs_when_tenpai_normal_hands
    outs = @evaluator.count_outs(@tenpai_normal_hands) # 有効牌：2種8枚 (36索)
    normal_outs = outs[:normal]
    outs_kind = normal_outs.map(&:code).uniq.size
    outs_count = normal_outs.size
    outs_names = normal_outs.map(&:name).uniq
    assert_equal 2, outs_kind
    assert_equal 8, outs_count
    assert_equal %w[3索 6索], outs_names
  end

  def test_count_outs_when_normal_hands
    outs = @evaluator.count_outs(@normal_hands) # 有効牌：19種68枚 (36789萬 6789筒 123456789索 東)
    normal_outs = outs[:normal]
    outs_kind = normal_outs.map(&:code).uniq.size
    outs_count = normal_outs.size
    outs_names = normal_outs.map(&:name).uniq
    assert_equal 19, outs_kind
    assert_equal 68, outs_count
    assert_equal %w[3萬 6萬 7萬 8萬 9萬 6筒 7筒 8筒 9筒 1索 2索 3索 4索 5索 6索 7索 8索 9索 東], outs_names
  end

  def test_count_outs_when_tenpai_chiitoitsu_hands
    outs = @evaluator.count_outs(@tenpai_chiitoitsu_hands) # 有効牌：1種3枚 (東)
    chiitoitsu_outs = outs[:chiitoitsu]
    outs_kind = chiitoitsu_outs.map(&:code).uniq.size
    outs_count = chiitoitsu_outs.size
    outs_names = chiitoitsu_outs.map(&:name).uniq
    assert_equal 1, outs_kind
    assert_equal 3, outs_count
    assert_equal ['東'], outs_names
  end

  def test_count_outs_when_chiitoitsu_hands
    outs = @evaluator.count_outs(@chiitoitsu_hands) # 有効牌：3種9枚 (4索 東 白)
    chiitoitsu_outs = outs[:chiitoitsu]
    outs_kind = chiitoitsu_outs.map(&:code).uniq.size
    outs_count = chiitoitsu_outs.size
    outs_names = chiitoitsu_outs.map(&:name).uniq
    assert_equal 3, outs_kind
    assert_equal 9, outs_count
    assert_equal %w[4索 東 白], outs_names
  end

  def test_count_outs_when_tenpai_kokushi_hands_without_head
    outs = @evaluator.count_outs(@tenpai_kokushi_hands_without_head) # 有効牌：13種39枚 (19萬 19筒 19索 東 南 西 北 白 發 中)
    kokushi_outs = outs[:kokushi]
    outs_kind = kokushi_outs.map(&:code).uniq.size
    outs_count = kokushi_outs.size
    outs_names = kokushi_outs.map(&:name).uniq
    assert_equal 13, outs_kind
    assert_equal 39, outs_count
    assert_equal %w[1萬 9萬 1筒 9筒 1索 9索 東 南 西 北 白 發 中], outs_names
  end

  def test_count_outs_when_tenpai_kokushi_hands_with_head
    outs = @evaluator.count_outs(@tenpai_kokushi_hands_with_head) # 有効牌：1種4枚 (中)
    kokushi_outs = outs[:kokushi]
    outs_kind = kokushi_outs.map(&:code).uniq.size
    outs_count = kokushi_outs.size
    outs_names = kokushi_outs.map(&:name).uniq
    assert_equal 1, outs_kind
    assert_equal 4, outs_count
    assert_equal ['中'], outs_names
  end

  def test_count_outs_when_kokushi_hands_without_head
    outs = @evaluator.count_outs(@kokushi_hands_without_head) # 有効牌：13種42枚 (19萬 19筒 19索 東 南 西 北 白 發 中)
    kokushi_outs = outs[:kokushi]
    outs_kind = kokushi_outs.map(&:code).uniq.size
    outs_count = kokushi_outs.size
    outs_names = kokushi_outs.map(&:name).uniq
    assert_equal 13, outs_kind
    assert_equal 42, outs_count
    assert_equal %w[1萬 9萬 1筒 9筒 1索 9索 東 南 西 北 白 發 中], outs_names
  end

  def test_count_outs_when_kokushi_hands_with_head
    outs = @evaluator.count_outs(@kokushi_hands_with_head) # 有効牌：2種8枚 (北 中)
    kokushi_outs = outs[:kokushi]
    outs_kind = kokushi_outs.map(&:code).uniq.size
    outs_count = kokushi_outs.size
    outs_names = kokushi_outs.map(&:name).uniq
    assert_equal 2, outs_kind
    assert_equal 8, outs_count
    assert_equal %w[北 中], outs_names
  end

  def test_calculate_minimum_shanten_when_tenpai_normal_hands
    shanten = @evaluator.calculate_minimum_shanten(@tenpai_normal_hands) # 向聴数：0
    assert_equal 0, shanten
  end

  def test_calculate_minimum_shanten_when_normal_hands
    shanten = @evaluator.calculate_minimum_shanten(@normal_hands) # 向聴数：3
    assert_equal 3, shanten
  end

  def test_calculate_minimum_shanten_when_tenpai_chiitoitsu_hands
    shanten = @evaluator.calculate_minimum_shanten(@tenpai_chiitoitsu_hands) # 向聴数：0
    assert_equal 0, shanten
  end

  def test_calculate_minimum_shanten_when_chiitoitsu_hands
    shanten = @evaluator.calculate_minimum_shanten(@chiitoitsu_hands) # 向聴数：1
    assert_equal 1, shanten
  end

  def test_calculate_minimum_shanten_when_tenpai_kokushi_hands_without_head
    shanten = @evaluator.calculate_minimum_shanten(@tenpai_kokushi_hands_without_head) # 向聴数：0
    assert_equal 0, shanten
  end

  def test_calculate_minimum_shanten_when_tenpai_kokushi_hands_with_head
    shanten = @evaluator.calculate_minimum_shanten(@tenpai_kokushi_hands_with_head) # 向聴数：0
    assert_equal 0, shanten
  end

  def test_calculate_minimum_shanten_when_kokushi_hands_without_head
    shanten = @evaluator.calculate_minimum_shanten(@kokushi_hands_without_head) # 向聴数：3
    assert_equal 3, shanten
  end

  def test_calculate_minimum_shanten_when_kokushi_hands_with_head
    shanten = @evaluator.calculate_minimum_shanten(@kokushi_hands_with_head) # 向聴数：1
    assert_equal 1, shanten
  end

  def test_calculate_shanten_when_normal_hands
    shanten = @evaluator.calculate_shanten(@normal_hands)
    assert_equal 3, shanten[:normal]
    assert_equal 4, shanten[:chiitoitsu]
    assert_equal 9, shanten[:kokushi]
  end

  def test_calculate_shanten_when_chiitoitsu_hands
    shanten = @evaluator.calculate_shanten(@chiitoitsu_hands)
    assert_equal 3, shanten[:normal]
    assert_equal 1, shanten[:chiitoitsu]
    assert_equal 9, shanten[:kokushi]
  end

  def test_calculate_shanten_when_kokushi_hands
    shanten = @evaluator.calculate_shanten(@kokushi_hands_without_head)
    assert_equal 8, shanten[:normal]
    assert_equal 6, shanten[:chiitoitsu]
    assert_equal 3, shanten[:kokushi]
  end

  def test_agari?
    assert_equal true, @evaluator.agari?(@agari_hands)
    assert_equal false, @evaluator.agari?(@normal_hands)
  end

  def test_tenpai?
    assert_equal true, @evaluator.tenpai?(@tenpai_normal_hands)
    assert_equal false, @evaluator.tenpai?(@normal_hands)
  end
end
