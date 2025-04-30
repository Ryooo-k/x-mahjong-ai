# frozen_string_literal: true

require_relative '../agent/agent_manager'
require_relative 'logic/hand_evaluator'

class Player
  attr_reader :id, :hands, :score, :point_histories, :hand_histories, :rivers, :is_menzen, :agent, :shanten_histories, :outs_histories

  HandEvaluator = Domain::Logic::HandEvaluator
  MAX_CALL_COUNT = 4

  def initialize(id, discard_agent_config, call_agent_config)
    @id = id
    @agent = AgentManager.new(discard_agent_config, call_agent_config)
    reset
  end

  def reset
    @score = 25_000
    @point_histories = []
    @agent.reset
    restart
    self
  end

  def restart
    @hands = []
    @hand_histories = []
    @called_tile_table = []
    @rivers = []
    @shanten_histories = []
    @outs_histories = []
    @is_menzen = true
  end

  def sorted_hands
    @hands.sort_by(&:id)
  end

  def called_tile_table
    tile_table = Array.new(MAX_CALL_COUNT) { [] }
    @called_tile_table.each_with_index do |tiles, order|
      tile_table[order] = tiles
    end
    tile_table
  end

  def add_point(point)
    @score += point
    @point_histories << point
  end

  def draw(tile)
    tile.holder = self
    @hands << tile
  end

  def discard(tile)
    raise ArgumentError, '手牌に無い牌は選択できません。' unless @hands.include?(tile)

    @hands.delete(tile)
    @rivers << tile
  end

  def record_hand_status
    record_hands
    record_shanten
    record_outs
  end

  def get_discard_action(states)
    @agent.get_discard_action(states)
  end

  def update_discard_agent(states, action, reward, next_states, done)
    @agent.update_discard_agent(states, action, reward, next_states, done)
  end

  def sync_qnet
    @agent.sync_qnet
  end

  def pong(combinations, target_tile)
    raise ArgumentError, '有効な牌が無いためポンできません。' unless can_call_pong?(target_tile)
    preform_call(combinations, target_tile:)
  end

  def chow(combinations, target_tile)
    raise ArgumentError, '有効な牌が無いためチーできません。' unless can_call_chow?(target_tile)
    preform_call(combinations, target_tile:)
  end

  def concealed_kong(combinations)
    raise ArgumentError, '有効な牌が無いため暗カンできません。' unless can_call_concealed_kong?(combinations)
    preform_call(combinations)
  end

  def open_kong(combinations, target_tile)
    raise ArgumentError, '有効な牌が無いため大明カンできません。' unless can_call_open_kong?(target_tile)
    preform_call(combinations, target_tile:)
  end

  def extended_kong(target_tile)
    raise ArgumentError, '有効な牌が無いため加カンできません。' unless can_call_extended_kong?(target_tile)

    @called_tile_table.each do |called_tiles|
      called_codes = called_tiles.map(&:code)
      called_tiles << target_tile if called_codes.uniq.size == 1 && called_codes.first == target_tile.code
    end
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

  def can_call_pong?(target)
    hand_codes = @hands.map(&:code)
    hand_codes.count(target.code) >= 2
  end

  def can_call_chow?(target)
    return false if target.code >= 27 # 字牌はチーできないので早期return

    hand_codes = @hands.map(&:code)
    possible_chow_table = build_possible_chow_table(target)
    possible_chow_table.any? do |possible_chow_codes|
      possible_chow_codes.all? { |code| hand_codes.include?(code) }
    end
  end

  def can_call_concealed_kong?(combinations)
    target_codes = combinations.map(&:code)
    return false if combinations.size != 4 || target_codes.uniq.size != 1

    target_code = target_codes.first
    hand_codes = @hands.map(&:code)
    hand_codes.count(target_code) == 4
  end

  def can_call_open_kong?(target)
    hand_codes = @hands.map(&:code)
    hand_codes.count(target.code) == 3
  end

  def can_call_extended_kong?(target)
    pong_code_table = @called_tile_table.map do |called_tiles|
      called_codes = called_tiles.map(&:code)
      called_codes.uniq.size == 1 ? called_codes : next
    end

    pong_code_table.any?{ |pong_codes| pong_codes.count(target.code) == 3 }
  end

  def preform_call(combinations, target_tile: false)
    called_tiles = combinations.dup
    target_tile.holder = self if target_tile
    called_tiles << target_tile if target_tile

    @called_tile_table << called_tiles
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
