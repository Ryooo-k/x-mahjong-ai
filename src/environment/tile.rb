# frozen_string_literal: true

class Tile
  attr_reader :id, :code, :name, :dora
  attr_accessor :holder

  TILE_DEFINITIONS = {
    0 => { code: 0, ids: (0..3).to_a, name: '1萬' },
    1 => { code: 1, ids: (4..7).to_a, name: '2萬' },
    2 => { code: 2, ids: (8..11).to_a, name: '3萬' },
    3 => { code: 3, ids: (12..15).to_a, name: '4萬' },
    4 => { code: 4, ids: (16..19).to_a, name: '5萬' },
    5 => { code: 5, ids: (20..23).to_a, name: '6萬' },
    6 => { code: 6, ids: (24..27).to_a, name: '7萬' },
    7 => { code: 7, ids: (28..31).to_a, name: '8萬' },
    8 => { code: 8, ids: (32..35).to_a, name: '9萬' },
  
    9 => { code: 9, ids: (36..39).to_a, name: '1筒' },
    10 => { code: 10, ids: (40..43).to_a, name: '2筒' },
    11 => { code: 11, ids: (44..47).to_a, name: '3筒' },
    12 => { code: 12, ids: (48..51).to_a, name: '4筒' },
    13 => { code: 13, ids: (52..55).to_a, name: '5筒' },
    14 => { code: 14, ids: (56..59).to_a, name: '6筒' },
    15 => { code: 15, ids: (60..63).to_a, name: '7筒' },
    16 => { code: 16, ids: (64..67).to_a, name: '8筒' },
    17 => { code: 17, ids: (68..71).to_a, name: '9筒' },
  
    18 => { code: 18, ids: (72..75).to_a, name: '1索' },
    19 => { code: 19, ids: (76..79).to_a, name: '2索' },
    20 => { code: 20, ids: (80..83).to_a, name: '3索' },
    21 => { code: 21, ids: (84..87).to_a, name: '4索' },
    22 => { code: 22, ids: (88..91).to_a, name: '5索' },
    23 => { code: 23, ids: (92..95).to_a, name: '6索' },
    24 => { code: 24, ids: (96..99).to_a, name: '7索' },
    25 => { code: 25, ids: (100..103).to_a, name: '8索' },
    26 => { code: 26, ids: (104..107).to_a, name: '9索' },
  
    27 => { code: 27, ids: (108..111).to_a, name: '東' },
    28 => { code: 28, ids: (112..115).to_a, name: '南' },
    29 => { code: 29, ids: (116..119).to_a, name: '西' },
    30 => { code: 30, ids: (120..123).to_a, name: '北' },

    31 => { code: 31, ids: (124..127).to_a, name: '白' },
    32 => { code: 32, ids: (128..131).to_a, name: '發' },
    33 => { code: 33, ids: (132..135).to_a, name: '中' }
  }.freeze

  def initialize(id, tile_code, is_red_dora = false)
    raise ArgumentError, '無効なIDもしくはcodeです。' unless validate_id?(id, tile_code)

    @id = id
    @code = tile_code
    @name = TILE_DEFINITIONS[tile_code][:name]
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

  def validate_id?(id, code)
    target_ids = TILE_DEFINITIONS[code][:ids]
    target_ids.include?(id)
  end
end
