# frozen_string_literal: true

class Tile
  attr_reader :id, :code, :name, :dora
  attr_accessor :holder

  TILE_DEFINITIONS = {
    # id：各牌毎にそれぞれ0〜135の一意な値で設定。1萬から順に0,1,3,...,135と設定。
    # suit：萬子は0、筒子は1、索子は2、字牌は3で設定
    # number：数牌はそれぞれの数字と同じ値（1〜9）で設定、字牌は東から順に1,2,3...と設定
    # code：suit * 10 + numberで設定。　
    # name：それぞれの牌の表示名を設定。
    # 萬子→筒子→索子→字牌の順番とする。
  }

  def initialize(id, is_red_dora: false)
    raise ArgumentError, '無効なIDです。' unless (0..135).to_a.include?(id)

    build_tile_definitions
    @id = id
    @suit = TILE_DEFINITIONS[id][:suit]
    @number = TILE_DEFINITIONS[id][:number]
    @code = TILE_DEFINITIONS[id][:code]
    @name = TILE_DEFINITIONS[id][:name]
    @holder = nil
    red_dora_count = is_red_dora ? 1 : 0
    @dora = {
      open: { code: 0, name: 'ドラ', count: 0 },
      blind: { code: 1, name: '裏ドラ', count: 0 },
      red: { code: 2, name: '赤ドラ', count: red_dora_count }
    }
  end

  def increase_open_dora_count
    @dora[:open][:count] += 1
  end

  def increase_blind_dora_count
    @dora[:blind][:count] += 1
  end

  def red_dora?
    @dora[:red][:count] != 0
  end

  private

  def build_tile_definitions
      # 萬子（1萬〜9萬）
    (1..9).each_with_index do |num, i|
      define_tile(start_id: i * 4, suit: 0, number: num, name: "#{num}萬")
    end

      # 筒子（1筒〜9筒）
    (1..9).each_with_index do |num, i|
     define_tile(start_id: 36 + i * 4, suit: 1, number: num, name: "#{num}筒")
    end
  
    # 索子（1索〜9索）
    (1..9).each_with_index do |num, i|
      define_tile(start_id: 72 + i * 4, suit: 2, number: num, name: "#{num}索")
    end
  
    # 字牌
    %w[東 南 西 北 白 發 中].each_with_index do |name, i|
      define_tile(start_id: 108 + i * 4, suit: 3, number: i + 1, name:)
    end
  end

  def define_tile(start_id:, suit:, number:, name:)
    same_tile_count = 4
    same_tile_count.times do |i|
      id = start_id + i
      code = suit * 10 + number
      TILE_DEFINITIONS[id] = { id:, suit:, number:, code:, name: }
    end
  end
end
