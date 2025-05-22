# frozen_string_literal: true

require 'test/unit'
require_relative '../../src/domain/player'
require_relative '../../src/domain/tile'
require_relative '../util/file_loader'

class PlayerTest < Test::Unit::TestCase
  def setup
    @config = FileLoader.load_parameter
    @player = Player.new(0, @config['agent'])
    @other_player = Player.new(1, @config['agent'])
    @tiles = Array.new(136) { |id| Tile.new(id) }
    @manzu_1 = @tiles[0]
  end

  def test_player_initialization
    old_agent = @player.agent.dup

    assert_equal 25_000, @player.score
    assert_not_equal old_agent, @player.agent
    assert_equal [], @player.point_histories
    assert_equal [], @player.hands
    assert_equal [], @player.hand_histories
    assert_equal [], @player.melds_list
    assert_equal [], @player.rivers
    assert_equal [], @player.shanten_histories
    assert_equal [], @player.outs_histories
    assert_equal true, @player.menzen?
    assert_equal false, @player.riichi?
    assert_equal nil, @player.wind
    assert_equal nil, @player.rank
  end

  def test_can_set_player_wind
    @player.wind = '1z'
    assert_equal '1z', @player.wind
  end

  def test_can_set_player_rank
    @player.rank = 1
    assert_equal 1, @player.rank
  end

  def test_riichi
    # 111222萬 333筒 444索 東中
    hands = [
      @tiles[0], @tiles[1], @tiles[2],
      @tiles[4], @tiles[5], @tiles[6],
      @tiles[44], @tiles[45], @tiles[46],
      @tiles[84], @tiles[85], @tiles[86],
      @tiles[108], @tiles[132]
    ]
    @player.instance_variable_set(:@hands, hands)
    assert_equal false, @player.riichi?

    east = @tiles[108]
    @player.riichi(east)
    assert_equal true, @player.riichi?
    assert_not_include @player.hands, east
    assert_equal [east], @player.rivers
  end

  def test_sorted_hands_return_hands_sorted_by_id
    manzu_1 = @tiles[0]
    manzu_2 = @tiles[4]
    east = @tiles[108]
    @player.draw(east)
    @player.draw(manzu_2)
    @player.draw(manzu_1)
    assert_equal [east, manzu_2, manzu_1], @player.hands
    assert_equal [manzu_1, manzu_2, east], @player.sorted_hands
  end

  def test_award_point
    assert_equal 25_000, @player.score
  
    @player.award_point(8_000)
    assert_equal 33_000, @player.score
    assert_equal [8_000], @player.point_histories
  
    @player.award_point(-12_000)
    assert_equal 21_000, @player.score
    assert_equal [8_000, -12_000], @player.point_histories
  end

  def test_add_tile_to_hands_when_player_drew
    @player.draw(@manzu_1)
    assert_equal [@manzu_1], @player.hands

    manzu_2 = @tiles[4]
    @player.draw(manzu_2)
    assert_equal [@manzu_1, manzu_2], @player.hands
  end

  def test_holder_is_set_when_player_drew
    assert_not_equal @player, @manzu_1.holder
    @player.draw(@manzu_1)
    assert_equal @player, @manzu_1.holder
  end

  def test_remove_tile_from_hand_when_player_discarded
    manzu_2 = @tiles[4]
    @player.draw(@manzu_1)
    @player.draw(manzu_2)
    assert_equal [@manzu_1, manzu_2], @player.hands

    @player.discard(@manzu_1)
    assert_equal [manzu_2], @player.hands
  end

  def test_add_tile_from_river_when_player_discarded
    assert_equal [], @player.rivers
    @player.draw(@manzu_1)
    @player.discard(@manzu_1)
    assert_equal [@manzu_1], @player.rivers
  end

  def test_choose
    # 東　123456789萬 123筒
    hands = [
      @tiles[108],
      @tiles[1], @tiles[4], @tiles[8], 
      @tiles[12], @tiles[16], @tiles[20],
      @tiles[24], @tiles[28], @tiles[32],
      @tiles[36], @tiles[40], @tiles[44]
    ]
    @player.instance_variable_set(:@hands, hands)
    index = 0
    target = @player.choose(index)
    assert_equal @tiles[1], target
  end

  def test_record_hand_status
    # 123456789萬 123筒　東
    # 向聴数：0
    # 有効牌数：3
    hands = [
      @tiles[0], @tiles[4], @tiles[8], 
      @tiles[12], @tiles[16], @tiles[20],
      @tiles[24], @tiles[28], @tiles[32],
      @tiles[36], @tiles[40], @tiles[44],
      @tiles[108]
    ]
    @player.instance_variable_set(:@hands, hands)
    @player.record_hand_status

    assert_equal [hands], @player.hand_histories
    assert_equal [0], @player.shanten_histories
    assert_equal [3], @player.outs_histories
  end

  def test_agari?
    # 123456789萬 123筒　東東
    hands = [
      @tiles[0], @tiles[4], @tiles[8],
      @tiles[12], @tiles[16], @tiles[20],
      @tiles[24], @tiles[28], @tiles[32],
      @tiles[36], @tiles[40], @tiles[44],
      @tiles[108], @tiles[109]
    ]

    assert_equal false, @player.agari?
    @player.instance_variable_set(:@hands, hands)
    assert_equal true, @player.agari?
  end

  def test_tenpai?
    # 123456789萬 123筒　東
    hands = [
      @tiles[0], @tiles[4], @tiles[8],
      @tiles[12], @tiles[16], @tiles[20],
      @tiles[24], @tiles[28], @tiles[32],
      @tiles[36], @tiles[40], @tiles[44],
      @tiles[108]
    ]

    assert_equal false, @player.tenpai?
    @player.instance_variable_set(:@hands, hands)
    assert_equal true, @player.tenpai?
  end

  def test_can_pon
    # 123456789萬 112筒　東
    hands = [
      @tiles[0], @tiles[4], @tiles[8],
      @tiles[12], @tiles[16], @tiles[20],
      @tiles[24], @tiles[28], @tiles[32],
      @tiles[36], @tiles[37], @tiles[40],
      @tiles[108]
    ]
    @player.instance_variable_set(:@hands, hands)
    pinzu_1 = @tiles[38]
    result = @player.can_pon?(pinzu_1)
    assert_equal true, result

    east = @tiles[109]
    result = @player.can_pon?(east)
    assert_equal false, result
  end

  def test_can_chi
    # 123456789萬 112筒　東
    hands = [
      @tiles[0], @tiles[4], @tiles[8],
      @tiles[12], @tiles[16], @tiles[20],
      @tiles[24], @tiles[28], @tiles[32],
      @tiles[36], @tiles[37], @tiles[40],
      @tiles[108]
    ]
    @player.instance_variable_set(:@hands, hands)
    pinzu_3 = @tiles[44]
    result = @player.can_chi?(pinzu_3)
    assert_equal true, result

    pinzu_4 = @tiles[48]
    result = @player.can_chi?(pinzu_4)
    assert_equal false, result
  end

  def test_can_ankan
    # 123456789萬 1111筒 東
    hands = [
      @tiles[0], @tiles[4], @tiles[8],
      @tiles[12], @tiles[16], @tiles[20],
      @tiles[24], @tiles[28], @tiles[32],
      @tiles[36], @tiles[37], @tiles[38], @tiles[39],
      @tiles[108]
    ]
    @player.instance_variable_set(:@hands, hands)
    result = @player.can_ankan?
    assert_equal true, result

    @player.discard(@tiles[39])
    result = @player.can_ankan?
    assert_equal false, result
  end

  def test_can_daiminkan
    # 123456789萬 111筒 東
    hands = [
      @tiles[0], @tiles[4], @tiles[8],
      @tiles[12], @tiles[16], @tiles[20],
      @tiles[24], @tiles[28], @tiles[32],
      @tiles[36], @tiles[37], @tiles[38],
      @tiles[108]
    ]
    @player.instance_variable_set(:@hands, hands)
    pinzu_1 = @tiles[39]
    result = @player.can_daiminkan?(pinzu_1)
    assert_equal true, result

    east = @tiles[109]
    result = @player.can_daiminkan?(east)
    assert_equal false, result
  end

  def test_can_kakan
    # 456789萬 1筒
    hands = [
      @tiles[12], @tiles[16], @tiles[20],
      @tiles[24], @tiles[28], @tiles[32],
      @tiles[39]
    ]

    # 123萬 111筒
    melds_list = [
      [@tiles[0], @tiles[4], @tiles[8]],
      [@tiles[36], @tiles[37], @tiles[38]]
    ]
    @player.instance_variable_set(:@hands, hands)
    @player.instance_variable_set(:@melds_list, melds_list)
    result = @player.can_kakan?
    assert_equal true, result

    pinzu_1 = @tiles[39]
    @player.discard(pinzu_1)
    result = @player.can_kakan?
    assert_equal false, result
  end

  def test_can_riichi
    # melds_listを見直してテストを実装する
  end

  def test_can_ron_return_yaku_when_player_can_ron
    # 123456789萬 123筒 東
    # 待ち牌：東
    tiles = [
      @tiles[0], @tiles[4], @tiles[8],
      @tiles[12], @tiles[16], @tiles[20],
      @tiles[24], @tiles[28], @tiles[32],
      @tiles[36], @tiles[40], @tiles[44],
      @tiles[108]
    ]
    tiles.each { |tile| @player.draw(tile) }
    
    @player.wind = '1z'
    round_wind = '1z'
    haku = @tiles[124]
    assert_equal false, @player.can_ron?(haku, round_wind)

    east = @tiles[109]
    result = @player.can_ron?(east, round_wind)
    assert_equal [{"han"=>2, "name"=>"一気通貫"}], result
  end

  def test_can_ron_return_false_when_player_can_not_ron
    # 123456789萬 135筒 東
    # 待ち牌：東
    tiles = [
      @tiles[0], @tiles[4], @tiles[8],
      @tiles[12], @tiles[16], @tiles[20],
      @tiles[24], @tiles[28], @tiles[32],
      @tiles[36], @tiles[44], @tiles[52],
      @tiles[108]
    ]
    tiles.each { |tile| @player.draw(tile) }
    
    @player.wind = '1z'
    round_wind = '1z'
    haku = @tiles[124]
    assert_equal false, @player.can_ron?(haku, round_wind)

    east = @tiles[109]
    result = @player.can_ron?(east, round_wind)
    assert_equal false, result
  end

  def test_can_tsumo_return_yaku_when_player_can_tsumo
    # 123456789萬 123筒 東東
    tiles = [
      @tiles[0], @tiles[4], @tiles[8],
      @tiles[12], @tiles[16], @tiles[20],
      @tiles[24], @tiles[28], @tiles[32],
      @tiles[36], @tiles[40], @tiles[44],
      @tiles[108], @tiles[109]
    ]
    tiles.each { |tile| @player.draw(tile)}
    
    @player.wind = '1z'
    round_wind = '1z'
    result = @player.can_tsumo?(round_wind)
    assert_equal [{ "han" => 1, "name" => "門前清自摸和" }, { "han" => 2, "name" => "一気通貫" }], result
  end

  def test_can_tsumo_return_false_when_player_can_not_tsumo
    # 123456789萬 123筒 東中
    tiles = [
      @tiles[0], @tiles[4], @tiles[8],
      @tiles[12], @tiles[16], @tiles[20],
      @tiles[24], @tiles[28], @tiles[32],
      @tiles[36], @tiles[40], @tiles[44],
      @tiles[108], @tiles[132]
    ]
    tiles.each { |tile| @player.draw(tile)}
    
    @player.wind = '1z'
    round_wind = '1z'
    result = @player.can_tsumo?(round_wind)
    assert_equal false, result
  end

  def test_tile_holder_change_to_called_player_when_preform_called
    manzu_3_id8 = @tiles[8]
    @other_player.draw(manzu_3_id8)
    assert_equal @other_player, manzu_3_id8.holder

    manzu_3_id9 = @tiles[9]
    manzu_3_id10 = @tiles[10]
    combinations = [manzu_3_id9, manzu_3_id10]
    @player.draw(manzu_3_id9)
    @player.draw(manzu_3_id10)
    @player.pon(combinations, manzu_3_id8)
    assert_equal @player, manzu_3_id8.holder
  end

  def test_hands_delete_target_tiles_when_player_called_pon
    manzu_3_id8 = @tiles[8]
    manzu_3_id9 = @tiles[9]
    manzu_3_id10 = @tiles[10]

    combinations = [manzu_3_id9, manzu_3_id10]
    @player.draw(@manzu_1)
    @player.draw(manzu_3_id9)
    @player.draw(manzu_3_id10)
    @player.pon(combinations, manzu_3_id8)

    called_tiles = combinations << manzu_3_id8
    @player.hands.each { |tile| assert_not_include(called_tiles, tile) }
  end

  def test_melds_list_add_target_tiles_when_player_called_pon
    manzu_3_id8 = @tiles[8]
    manzu_3_id9 = @tiles[9]
    manzu_3_id10 = @tiles[10]

    combinations = [manzu_3_id9, manzu_3_id10]
    @player.draw(manzu_3_id9)
    @player.draw(manzu_3_id10)
    @player.pon(combinations, manzu_3_id8)

    called_tiles = combinations << manzu_3_id8
    assert_equal [called_tiles], @player.melds_list
  end

  def test_can_not_call_pong_when_combinations_not_in_hand
    manzu_3_id8 = @tiles[8]
    manzu_3_id9 = @tiles[9]
    manzu_3_id10 = @tiles[10]

    combinations = [manzu_3_id9, manzu_3_id10]
    error = assert_raise(ArgumentError) { @player.pon(combinations, manzu_3_id8) }
    assert_equal '有効な牌が無いためポンできません。', error.message
  end

  def test_can_not_call_chow_when_combinations_not_in_hand
    manzu_2 = @tiles[4]
    manzu_3 = @tiles[8]

    combinations = [@manzu_1, manzu_2]
    error = assert_raise(ArgumentError) { @player.chi(combinations, manzu_3) }
    assert_equal '有効な牌が無いためチーできません。', error.message
  end

  def test_hands_delete_target_tiles_when_player_called_ankan
    manzu_3_id8 = @tiles[8]
    manzu_3_id9 = @tiles[9]
    manzu_3_id10 = @tiles[10]
    manzu_3_id11 = @tiles[11]

    @player.draw(manzu_3_id8)
    @player.draw(manzu_3_id9)
    @player.draw(manzu_3_id10)
    @player.draw(manzu_3_id11)
    @player.draw(@manzu_1)
    combinations = [manzu_3_id8, manzu_3_id9, manzu_3_id10, manzu_3_id11]
    @player.ankan(combinations)
    @player.hands.each { |tile| assert_not_include(combinations, tile) }
  end

  def test_melds_list_add_target_tiles_when_player_called_ankan
    manzu_3_id8 = @tiles[8]
    manzu_3_id9 = @tiles[9]
    manzu_3_id10 = @tiles[10]
    manzu_3_id11 = @tiles[11]

    @player.draw(manzu_3_id8)
    @player.draw(manzu_3_id9)
    @player.draw(manzu_3_id10)
    @player.draw(manzu_3_id11)
    @player.draw(@manzu_1)
    combinations = [manzu_3_id8, manzu_3_id9, manzu_3_id10, manzu_3_id11]
    @player.ankan(combinations)
    assert_equal [combinations], @player.melds_list
  end

  def test_can_not_call_ankan_when_combinations_not_in_hand
    manzu_3_id8 = @tiles[8]
    manzu_3_id9 = @tiles[9]
    manzu_3_id10 = @tiles[10]
    manzu_3_id11 = @tiles[11]
    combinations = [manzu_3_id8, manzu_3_id9, manzu_3_id10, manzu_3_id11]
    error = assert_raise(ArgumentError) { @player.ankan(combinations) }
    assert_equal '有効な牌が無いため暗カンできません。', error.message
  end

  def test_can_not_call_daiminkan_when_combinations_not_in_hand
    manzu_3_id8 = @tiles[8]
    manzu_3_id9 = @tiles[9]
    manzu_3_id10 = @tiles[10]
    manzu_3_id11 = @tiles[11]

    combinations = [manzu_3_id8, manzu_3_id9, manzu_3_id10]
    error = assert_raise(ArgumentError) { @player.daiminkan(combinations, manzu_3_id11) }
    assert_equal '有効な牌が無いため大明カンできません。', error.message
  end

  def test_melds_list_add_target_tile_when_player_called_kakan
    # 123456789萬 1筒 東
    hands = [
      @tiles[0], @tiles[4], @tiles[8],
      @tiles[12], @tiles[16], @tiles[20],
      @tiles[24], @tiles[28], @tiles[32],
      @tiles[36],
      @tiles[108]
    ]

    # 111筒
    melds_list = [[@tiles[37], @tiles[38], @tiles[39]]]

    @player.instance_variable_set(:@hands, hands)
    @player.instance_variable_set(:@melds_list, melds_list)

    @player.kakan(@tiles[36])
    assert_equal [[@tiles[37], @tiles[38], @tiles[39], @tiles[36]]], @player.melds_list
  end

  def test_can_not_call_kakan_when_no_existing_pong
    # 123456789萬 123筒 東中
    hands = [
      @tiles[0], @tiles[4], @tiles[8],
      @tiles[12], @tiles[16], @tiles[20],
      @tiles[24], @tiles[28], @tiles[32],
      @tiles[36], @tiles[40], @tiles[44],
      @tiles[108], @tiles[132]
    ]
    @player.instance_variable_set(:@hands, hands)
    error = assert_raise(ArgumentError) { @player.kakan(@manzu_1) }
    assert_equal('有効な牌が無いため加カンできません。', error.message)
  end

  def test_restart
    @player.instance_variable_set(:@score, 33_000)
    @player.instance_variable_set(:@point_histories, [8_000])
    @player.instance_variable_set(:@hands, [@manzu_1])
    @player.instance_variable_set(:@hand_histories, [@manzu_1])
    @player.instance_variable_set(:@melds_list, [[@manzu_1]])
    @player.instance_variable_set(:@rivers, @manzu_1)
    @player.instance_variable_set(:@shanten_histories, [3, 2, 1, 0])
    @player.instance_variable_set(:@outs_histories, [13, 7, 4, 0])
    @player.instance_variable_set(:@is_menzen, false)
    @player.instance_variable_set(:@is_riichi, true)
    @player.instance_variable_set(:@wind, '1z')

    @player.restart
    assert_equal 33_000, @player.score
    assert_equal [8_000], @player.point_histories
    assert_equal [], @player.hands
    assert_equal [], @player.hand_histories
    assert_equal [], @player.melds_list
    assert_equal [], @player.rivers
    assert_equal [], @player.shanten_histories
    assert_equal [], @player.outs_histories
    assert_equal true, @player.menzen?
    assert_equal false, @player.riichi?
    assert_equal nil, @player.wind
  end

  def test_reset
    @player.instance_variable_set(:@score, 33_000)
    @player.instance_variable_set(:@point_histories, [8_000])
    @player.instance_variable_set(:@hands, [@manzu_1])
    @player.instance_variable_set(:@hand_histories, [@manzu_1])
    @player.instance_variable_set(:@melds_list, [[@manzu_1]])
    @player.instance_variable_set(:@rivers, @manzu_1)
    @player.instance_variable_set(:@shanten_histories, [3, 2, 1, 0])
    @player.instance_variable_set(:@outs_histories, [13, 7, 4, 0])
    @player.instance_variable_set(:@is_menzen, false)
    @player.instance_variable_set(:@is_riichi, true)
    @player.instance_variable_set(:@wind, '1z')

    @player.reset
    assert_equal 25_000, @player.score
    assert_equal [], @player.point_histories
    assert_equal [], @player.hands
    assert_equal [], @player.hand_histories
    assert_equal [], @player.melds_list
    assert_equal [], @player.rivers
    assert_equal [], @player.shanten_histories
    assert_equal [], @player.outs_histories
    assert_equal true, @player.menzen?
    assert_equal false, @player.riichi?
    assert_equal nil, @player.wind
  end
end
