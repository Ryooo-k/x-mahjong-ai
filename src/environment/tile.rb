# frozen_string_literal: true

class Tile
  attr_reader :id, :number, :name

  TILE_DEFINITIONS = {
    0 => { number: 0, ids: (0..3).to_a, name: '1萬' },
    1 => { number: 1, ids: (4..7).to_a, name: '2萬' },
    2 => { number: 2, ids: (8..11).to_a, name: '3萬' },
    3 => { number: 3, ids: (12..15).to_a, name: '4萬' },
    4 => { number: 4, ids: (16..19).to_a, name: '5萬' },
    5 => { number: 5, ids: (20..23).to_a, name: '6萬' },
    6 => { number: 6, ids: (24..27).to_a, name: '7萬' },
    7 => { number: 7, ids: (28..31).to_a, name: '8萬' },
    8 => { number: 8, ids: (32..35).to_a, name: '9萬' },
  
    9 => { number: 9, ids: (36..39).to_a, name: '1筒' },
    10 => { number: 10, ids: (40..43).to_a, name: '2筒' },
    11 => { number: 11, ids: (44..47).to_a, name: '3筒' },
    12 => { number: 12, ids: (48..51).to_a, name: '4筒' },
    13 => { number: 13, ids: (52..55).to_a, name: '5筒' },
    14 => { number: 14, ids: (56..59).to_a, name: '6筒' },
    15 => { number: 15, ids: (60..63).to_a, name: '7筒' },
    16 => { number: 16, ids: (64..67).to_a, name: '8筒' },
    17 => { number: 17, ids: (68..71).to_a, name: '9筒' },
  
    18 => { number: 18, ids: (72..75).to_a, name: '1索' },
    19 => { number: 19, ids: (76..79).to_a, name: '2索' },
    20 => { number: 20, ids: (80..83).to_a, name: '3索' },
    21 => { number: 21, ids: (84..87).to_a, name: '4索' },
    22 => { number: 22, ids: (88..91).to_a, name: '5索' },
    23 => { number: 23, ids: (92..95).to_a, name: '6索' },
    24 => { number: 24, ids: (96..99).to_a, name: '7索' },
    25 => { number: 25, ids: (100..103).to_a, name: '8索' },
    26 => { number: 26, ids: (104..107).to_a, name: '9索' },
  
    27 => { number: 27, ids: (108..111).to_a, name: '東' },
    28 => { number: 28, ids: (112..115).to_a, name: '南' },
    29 => { number: 29, ids: (116..119).to_a, name: '西' },
    30 => { number: 30, ids: (120..123).to_a, name: '北' },
    31 => { number: 31, ids: (124..127).to_a, name: '白' },
    32 => { number: 32, ids: (128..131).to_a, name: '發' },
    33 => { number: 33, ids: (132..135).to_a, name: '中' }
  }.freeze

  def initialize(id, number, red_dora)
    raise ArgumentError, '無効なIDもしくはNUMBERです。' unless validate_tile_id?(id, number)

    @id = id
    @number = number
    @name = TILE_DEFINITIONS[number][:name]
    @red_dora = red_dora
  end

  def red_dora?
    @red_dora
  end

  private

  def validate_tile_id?(id, number)
    target_ids = TILE_DEFINITIONS[number][:ids]
    target_ids.include?(id)
  end
end
