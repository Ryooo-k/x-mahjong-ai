# frozen_string_literal: true

require_relative '../agent/agent_manager'
require_relative 'logic/hand_evaluator'

class Player
  attr_reader :id, :hands, :score, :point_histories, :hand_histories, :melds_list, :rivers, :agent, :shanten_histories, :outs_histories
  attr_accessor :wind, :rank

  HandEvaluator = Domain::Logic::HandEvaluator
  MAX_CALL_COUNT = 4

  def initialize(id, agent_config)
    @id = id
    @agent = AgentManager.new(agent_config['discard'], agent_config['call'], agent_config['riichi'], agent_config['tsumo'], agent_config['ron'])
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
    @ron_cache = {}
  end

  def menzen?
    @is_menzen
  end

  def riichi?
    @is_riichi
  end

  def riichi
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

  def can_ron?(tile, round_wind)
    return false if !tenpai?
    test_hands = sorted_hands + [tile]
    cache_code =  test_hands.map(&:code).join
    return @ron_cache[cache_code] if @ron_cache.key?(cache_code)

    result = HandEvaluator.has_yaku?(hands: @hands, melds_list: @melds_list, target_tile: tile, round_wind:, player_wind: @wind, is_riichi: @is_riichi)
    @ron_cache[cache_code] = result
    result
  end

  def choose(index)
    sorted_hands[index]
  end

  def get_discard_action(states)
    @agent.get_discard_action(states)
  end

  def get_call_action(states)
    @agent.get_call_action(states)
  end

  def get_riichi_action(states)
    @agent.get_riichi_action(states)
  end

  def get_tsumo_action(states)
    @agent.get_tsumo_action(states)
  end

  def get_ron_action(states)
    @agent.get_ron_action(states)
  end

  def update_discard_agent(states, action, reward, next_states, done)
    @agent.update_discard_agent(states, action, reward, next_states, done)
  end

  def update_call_agent(states, action, reward, next_states, done)
    @agent.update_call_agent(states, action, reward, next_states, done)
  end

  def update_riichi_agent(states, action, reward, next_states, done)
    @agent.update_riichi_agent(states, action, reward, next_states, done)
  end

  def update_tsumo_agent(states, action, reward, next_states, done)
    @agent.update_tsumo_agent(states, action, reward, next_states, done)
  end

  def update_ron_agent(states, action, reward, next_states, done)
    @agent.update_ron_agent(states, action, reward, next_states, done)
  end

  def sync_qnet
    @agent.sync_qnet
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
    raise ArgumentError, '有効な牌が無いため暗カンできません。' unless can_ankan?(combinations)
    preform_call(combinations)
  end

  def daiminkan(combinations, target_tile)
    raise ArgumentError, '有効な牌が無いため大明カンできません。' unless can_daiminkan?(target_tile)
    preform_call(combinations, target_tile:)
    @is_menzen = false
  end

  def kakan(target_tile)
    raise ArgumentError, '有効な牌が無いため加カンできません。' unless can_kakan?(target_tile)

    @melds_list.each do |called_tiles|
      called_codes = called_tiles.map(&:code)
      called_tiles << target_tile if called_codes.uniq.size == 1 && called_codes.first == target_tile.code
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
    @agent.reset
    restart
    self
  end

  private

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

  def can_pon?(target)
    hand_codes = @hands.map(&:code)
    hand_codes.count(target.code) >= 2
  end

  def can_chi?(target)
    return false if target.code >= 27 # 字牌はチーできないので早期return

    hand_codes = @hands.map(&:code)
    possible_chow_table = build_possible_chow_table(target)
    possible_chow_table.any? do |possible_chow_codes|
      possible_chow_codes.all? { |code| hand_codes.include?(code) }
    end
  end

  def can_ankan?(combinations)
    target_codes = combinations.map(&:code)
    return false if combinations.size != 4 || target_codes.uniq.size != 1

    target_code = target_codes.first
    hand_codes = @hands.map(&:code)
    hand_codes.count(target_code) == 4
  end

  def can_daiminkan?(target)
    hand_codes = @hands.map(&:code)
    hand_codes.count(target.code) == 3
  end

  def can_kakan?(target)
    pong_code_table = @melds_list.map do |called_tiles|
      called_codes = called_tiles.map(&:code)
      called_codes.uniq.size == 1 ? called_codes : next
    end

    pong_code_table.any?{ |pong_codes| pong_codes.count(target.code) == 3 }
  end

  def preform_call(combinations, target_tile: false)
    called_tiles = combinations.dup
    target_tile.holder = self if target_tile
    called_tiles << target_tile if target_tile

    @melds_list << called_tiles
    called_tiles.each { |tile| @hands.delete(tile) }
    @hand_histories << @hands.dup
  end

  def build_possible_chow_table(target)
    n = target.number
    code = target.code

    candidates = []
    candidates << [code + 1, code + 2] if n <= 7
    candidates << [code - 1, code + 1] if (2..8).include?(n)
    candidates << [code - 2, code - 1] if n >= 3
    candidates
  end
end
