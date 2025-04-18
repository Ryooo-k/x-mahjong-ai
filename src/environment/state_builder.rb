# frozen_string_literal: true

module StateBuilder
  TILE_COUNT = 34.0
  MAX_CALL_COUNT = 4.0
  ALL_SCORE = 100_000.0
  MAX_SHANTEN_COUNT = 8.0
  MAX_OUTS_COUNT = 13.0
  MAX_RIVER_COUNT = 24.0
  MAX_OPEN_DORA_COUNT = 5.0

  def self.build(current_player, other_players, table)
    current_plyer_states = build_current_player_states(current_player)
    other_players_states = build_other_players_states(other_players)
    table_states = build_table_states(table)

    states = [
      current_plyer_states,
      other_players_states,
      table_states
    ].flatten

    Torch.tensor(states, dtype: :float32)
  end

  private

  def build_current_player_states(player)
    hand_codes = to_codes_count(player.hands[:codes])
    called_tile_codes = to_code_table_count(player.called_tile_table[:codes])
    river_codes = to_normalized_river_codes(player.rivers)
    score = player.score / ALL_SCORE
    shanten = cal_shanten(player.hands[:tiles]) / MAX_SHANTEN_COUNT
    outs = count_outs(player.hands[:tiles]) / MAX_OUTS_COUNT

    [
      player.id,
      hand_codes,
      called_tile_codes,
      river_codes,
      score,
      shanten,
      outs
    ]
  end

  def build_other_players_states(players)
    players.map do |player|
      called_tile_codes = to_code_table_count(player.called_tile_table[:codes])
      river_codes = to_normalized_river_codes(player.rivers)
      score = player.score / ALL_SCORE
  
      [
        player.id,
        called_tile_codes,
        river_codes,
        score
      ]
    end
  end

  def build_table_states(table)
    remaining_tiles = table.remaining_tile_count
    open_dora_codes = to_normalized_dora_codes(table.open_dora_tiles)
    kong_count = table.kong_count
    round = table.round[:count]
    honba = table.honba[:count]
    host_id = table.host.id
    children_ids = table.children.map { |player| player.id }

    [
      remaining_tiles,
      open_dora_codes,
      kong_count,
      round,
      honba,
      host_id,
      children_ids
    ]
  end

  # 手牌の並び順の情報は失われる。
  def to_codes_count(codes)
    counters = Array.new(TILE_COUNT, 0)
    codes.each { |code| counters[code] += 1 }
    counters
  end

  def to_code_table_count(code_table)
    counter_table = Array.new(MAX_CALL_COUNT) { Array.new(TILE_COUNT, 0) }
    code_table.each_with_index do |codes, order|
      codes.each { |code| counter_table[order][code] += 1 }
    end
    counter_table
  end

  def to_normalized_river_codes(rivers)
    normalized_codes = Array.new(MAX_RIVER_COUNT, -1)
    rivers.each_with_index do |tile, order|
      normalized_codes[order] = tile.code / TILE_COUNT
    end
  end

  def to_normalized_dora_codes(dora_tiles)
    normalized_codes = Array.new(MAX_OPEN_DORA_COUNT, -1)
    dora_tiles.each_with_index do |tile, order|
      normalized_codes[order] = tile.code / TILE_COUNT
    end
  end
end
