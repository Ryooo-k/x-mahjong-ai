# frozen_string_literal: true

require_relative '../agent/discard_agent'
require_relative 'logic/hand_evaluator'

class Player
  attr_reader :id, :hands, :score, :point_histories, :hand_histories, :melds_list, :rivers, :agent, :shanten_histories, :outs_histories
  attr_accessor :wind, :rank, :loss, :tenpai_count

  HandEvaluator = Domain::Logic::HandEvaluator
  MAX_CALL_COUNT = 4

  def initialize(id, agent_config)
    @id = id
    @agent = DiscardAgent.new(agent_config)
    @score = 25_000
    @point_histories = []
    @hands = []
    @hand_histories = []
    @melds_list = []
    @rivers = []
    @shanten_histories = []
    @outs_histories = []
    @is_menzen = true
    @is_riichi = false
    @wind = nil
    @rank = nil
    @loss = 0
    @tenpai_count = 0
  end

  def menzen?
    @is_menzen
  end

  def riichi?
    @is_riichi
  end

  def riichi(tile)
    discard(tile)
    @is_riichi = true
  end

  def sorted_hands
    @hands.sort_by(&:id)
  end

  def award_point(point)
    @score += point
    @point_histories << point
  end

  def draw(tile)
    tile.holder = self
    @hands << tile
  end

  def discard(tile)
    @hands.delete(tile)
    @rivers << tile
  end

  def choose(index)
    sorted_hands[index]
  end

  def record_hand_status
    record_hands
    record_shanten
    record_outs
  end

  def agari?
    HandEvaluator.agari?(@hands)
  end

  def tenpai?
    HandEvaluator.tenpai?(@hands)
  end

  def can_pon?(tile)
    hand_codes.count(tile.code) >= 2
  end

  def can_chi?(tile)
    return false if tile.code >= 27 # 字牌はチーできないので早期return

    possible_chi_table = build_possible_chi_table(tile)
    possible_chi_table.any? do |possible_chi_codes|
      possible_chi_codes.all? { |code| hand_codes.include?(code) }
    end
  end

  def can_ankan?
    hand_codes.tally.any? { |_, count| count == 4 }
  end

  def can_daiminkan?(tile)
    hand_codes.count(tile.code) == 3
  end

  def can_kakan?
    pon_codes = @melds_list.map do |melds|
      codes = melds.map(&:code)
      codes.uniq.size == 1 && codes.size == 3 ? codes.uniq : next
    end.flatten

    hand_codes.any? { |code| pon_codes.include?(code) }
  end

  def can_riichi?
    @melds_list.empty? # 暗カンの場合はリーチできるので、melds_listの設定の仕方を見直す
  end

  def can_ron?(tile, round_wind)
    return false if !tenpai?
    HandEvaluator.has_yaku?(hands: @hands, melds_list: @melds_list, target_tile: tile, round_wind:, player_wind: @wind, is_tsumo: false, is_riichi: @is_riichi)
  end

  def can_tsumo?(round_wind)
    HandEvaluator.has_yaku?(hands: @hands[..-2], melds_list: @melds_list, target_tile: @hands.last, round_wind:, player_wind: @wind, is_tsumo: true, is_riichi: @is_riichi)
  end

  def pon(combinations, target_tile)
    raise ArgumentError, '有効な牌が無いためポンできません。' unless can_pon?(target_tile)
    preform_call(combinations, target_tile:)
    @is_menzen = false
  end

  def chi(combinations, target_tile)
    raise ArgumentError, '有効な牌が無いためチーできません。' unless can_chi?(target_tile)
    preform_call(combinations, target_tile:)
    @is_menzen = false
  end

  def ankan(combinations)
    raise ArgumentError, '有効な牌が無いため暗カンできません。' unless can_ankan?
    preform_call(combinations)
  end

  def daiminkan(combinations, target_tile)
    raise ArgumentError, '有効な牌が無いため大明カンできません。' unless can_daiminkan?(target_tile)
    preform_call(combinations, target_tile:)
    @is_menzen = false
  end

  def kakan(target_tile)
    raise ArgumentError, '有効な牌が無いため加カンできません。' unless can_kakan?

    @melds_list.each do |melds|
      melds_codes = melds.map(&:code)
      melds << target_tile if melds_codes.uniq.size == 1 && melds_codes.first == target_tile.code
    end
    @is_menzen = false
  end

  def restart
    @hands = []
    @hand_histories = []
    @melds_list = []
    @rivers = []
    @shanten_histories = []
    @outs_histories = []
    @is_menzen = true
    @is_riichi = false
    @wind = nil
  end

  def reset
    @score = 25_000
    @point_histories = []
    @loss = 0
    restart
    self
  end

  private

  def hand_codes
    hand_codes = @hands.map(&:code)
  end

  def record_hands
    @hand_histories << @hands.dup
  end

  def record_shanten
    shanten = HandEvaluator.calculate_minimum_shanten(@hands)
    @shanten_histories << shanten
  end

  def record_outs
    outs = HandEvaluator.count_minimum_outs(@hands)
    @outs_histories << outs
  end

  def preform_call(combinations, target_tile: false)
    called_tiles = combinations.dup
    target_tile.holder = self if target_tile
    called_tiles << target_tile if target_tile

    @melds_list << called_tiles
    called_tiles.each { |tile| @hands.delete(tile) }
    @hand_histories << @hands.dup
  end

  def build_possible_chi_table(target)
    n = target.number
    code = target.code

    candidates = []
    candidates << [code + 1, code + 2] if n <= 7
    candidates << [code - 1, code + 1] if (2..8).include?(n)
    candidates << [code - 2, code - 1] if n >= 3
    candidates
  end
end
