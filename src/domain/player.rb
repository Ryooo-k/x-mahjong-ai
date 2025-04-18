# frozen_string_literal: true

require_relative '../agent/agent_manager'

class Player
  attr_reader :score, :point_histories, :hand_histories, :rivers

  MAX_CALL_COUNT = 4

  def initialize(id, discard_agent_config, call_agent_config)
    @id = id
    @agent = AgentManager.new(discard_agent_config, call_agent_config)
    reset
  end

  def reset
    @score = 25_000
    @point_histories = []
    restart
    self
  end

  def restart
    @hands = []
    @hand_histories = []
    @called_tile_table = []
    @rivers = []
  end

  def hands
    {
      tiles: @hands,
      ids: @hands.map(&:id),
      suits: @hands.map(&:suit),
      numbers: @hands.map(&:number),
      codes: @hands.map(&:code),
      names: @hands.map(&:name)
    }
  end

  def sorted_hands
    sorted_hands = @hands.sort_by(&:id)

    {
      tiles: sorted_hands,
      ids: sorted_hands.map(&:id),
      suits: sorted_hands.map(&:suit),
      numbers: sorted_hands.map(&:number),
      codes: sorted_hands.map(&:code),
      names: sorted_hands.map(&:name)
    }
  end

  def called_tile_table
    tile_table = Array.new(MAX_CALL_COUNT) { [] }
    id_table = Array.new(MAX_CALL_COUNT) { [] }
    suit_table = Array.new(MAX_CALL_COUNT) { [] }
    number_table = Array.new(MAX_CALL_COUNT) { [] }
    code_table = Array.new(MAX_CALL_COUNT) { [] }
    name_table = Array.new(MAX_CALL_COUNT) { [] }

    @called_tile_table.each_with_index do |tiles, index|
      tile_table[index] = tiles
      id_table[index] = tiles.map { |tile| tile.id }
      suit_table[index] = tiles.map { |tile| tile.suit }
      number_table[index] =tiles.map { |tile| tile.number }
      code_table[index] = tiles.map { |tile| tile.code }
      name_table[index] = tiles.map { |tile| tile.name }
    end

    {
      tiles: tile_table,
      ids: id_table,
      suits: suit_table,
      numbers: number_table,
      codes: code_table,
      names: name_table
    }
  end

  def add_point(point)
    @score += point
    @point_histories << point
  end

  def record_hands
    @hand_histories << @hands.dup
  end

  def draw(tile)
    tile.holder = self
    @hands << tile
  end

  def play(tile)
    raise ArgumentError, '手牌に無い牌は選択できません。' unless @hands.include?(tile)

    @hands.delete(tile)
    @rivers << tile
    record_hands
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

  # def can_call?(target)
  #   can_call_pong?(target) || can_call_chow?(target) || can_call_open_kong?(target)
  # end

  # def can_pong_or_open_kong?(target)
  #   can_call_pong?(target) || can_call_open_kong?(target)
  # end

  private

  def can_call_pong?(target)
    hand_codes = @hands.map(&:code)
    hand_codes.count(target.code) >= 2
  end

  def can_call_chow?(target)
    return false if target.code >= 31 # 字牌はチーできないので早期return

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
