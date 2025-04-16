# frozen_string_literal: true

require 'json'
require_relative '../domain/table'

class MahjongEnv
  attr_reader :current_player, :other_players

  def initialize(table_config, player_config, shanten_list)
    @table = Table.new(table_config, player_config)
    @shanten_list = shanten_list
    @done = false
    @current_player = @table.host
    @other_players = @table.children
    @agari_number_table = build_agari_number_table
  end

  def reset
    @table.reset
  end

  def player_draw
    top_tile = @table.top_tile
    @current_player.draw(top_tile)
    @table.increase_draw_count
  end

  def step(action)
    return nil if @done
    now_hands = @current_player.sorted_hands[:tiles]
    @done = true if win?(now_hands) || game_over?

    target = now_hands[action]
    @current_player.play(target) unless win?(now_hands)

    old_hands = @current_player.hand_histories.last
    new_hands = @current_player.sorted_hands[:tiles]
    reward = cal_reward(old_hands, new_hands)

    next_states = build_states
    [next_states, reward, @done, target]
  end

  # def process_call_phase(target)
  #   @other_players.each do |player|
  #     next unless player.can_pong_or_open_kong?(target)

  #     call_action = player.get_call_action(states, target)
  #     if call_action == 0
  #       next
  #     elsif is_call == 1 # ポン
  #       player.pong(action)
  #     end
  #   end

  #   @other_players.first.can_call?(target)

  # end

  def states
    build_states
  end

  def info
    shantens = cal_shantens
    sorted_hands = build_player_hand_names
    shantens.zip(sorted_hands)
  end

  def rotate_turn
    seat_orders = @table.seat_orders
    current_number = seat_orders.each_index { |i| seat_orders[i] == @current_player }
    rotated_orders = seat_orders.rotate(current_number + 1)
    @current_player = rotated_orders.first
    @other_players = rotated_orders[1..]
  end

  def render
    # 学習結果を表示するためのメソッド
  end

  private

  # 向聴数を計算するのに使用するテーブル
  # 和了時に萬子、筒子、索子、字牌をそれぞれ何枚使用するか選定する
  def build_agari_number_table
    number_table = [0, 2, 3, 5, 6, 8, 9, 11, 12, 14].repeated_permutation(4).filter { |n| n.sum == 14 }
    # 和了に使用される牌はカンを除いた場合、合計で14個のみ。
    # ただし使用する牌の合計が14個かのチェックのみの場合、
    # [5, 2, 2, 5]などのあり得ない和了形が残ってしまう。
    # そのため和了形として正しい配列のみが残るように、3で割った余りの合計が2個（雀頭が一つ）かのチェックを行う。（国士無双、七対子は別のメソッドで確認する）
    number_table.delete_if { |numbers| numbers.map { |number| number % 3 }.sum != 2 }
  end

  def build_states
    current_plyer_states = build_current_player_states
    other_player_states = build_other_players_states
    table_states = build_table_states
    tile_wall_states = build_tile_wall_states

    states = [
      current_plyer_states,
      other_player_states,
      table_states,
      tile_wall_states
    ]

    Torch.tensor(states.flatten, dtype: :float32)
  end

  def build_current_player_states
    player = @current_player
    hand_codes = count_codes(player.hands[:tiles])
    called_tile_codes = count_codes(player.called_tile_table.flatten)
    river_codes = player.rivers.map { |tile| tile.code / 34 }  # 牌の種類数で正規化
    score = player.score / 100_000.0 # 4人の合計スコアで正規化
    shanten = cal_shanten(player.hands[:tiles]) / 8.0 # 最大の聴向数で正規化
    outs = count_outs(player.hands[:tiles]) / 13.0 # 最大の受け入れ枚数で正規化

    [
      hand_codes,
      called_tile_codes,
      river_codes,
      score,
      shanten,
      outs
    ]
  end

  def build_other_players_states
    players = @other_players
    players.map do |player|
      called_tile_codes = player.called_tile_table.flatten.map { |tile| tile.code / 34.0 } # 牌の種類数で正規化
      river_codes = player.rivers.map { |tile| tile.code / 34.0 } # 牌の種類数で正規化
      score = player.score / 100_000.0 # 4人の合計スコアで正規化
  
      [
        called_tile_codes,
        river_codes,
        score
      ]
    end
  end

  def build_table_states
    [
      @table.round[:count],
      @table.honba[:count]
    ]
  end

  def build_tile_wall_states
    open_dora_codes = @table.tile_wall.open_dora_codes.map { |code| code / 34.0 } # 牌の種類数で正規化
    blind_dora_codes = @table.tile_wall.blind_dora_codes.map { |code| code / 34.0 } # 牌の種類数で正規化
    kong_count = @table.tile_wall.kong_count

    [
      open_dora_codes,
      blind_dora_codes,
      kong_count
    ]
  end

  def build_player_hand_names
    @table.seat_orders.map { |player| player.sorted_hands[:tiles] }
  end

  def cal_shantens
    @table.seat_orders.map do |player|
      cal_shanten(player.hands[:tiles])
    end
  end

  def cal_shanten(hand_tiles)
    codes = count_codes(hand_tiles)
    manzu_code = codes[0..8].to_a.map(&:to_i).to_s
    pinzu_code = codes[9..17].to_a.map(&:to_i).to_s
    souzu_code = codes[18..26].to_a.map(&:to_i).to_s
    zihai_code = codes[27..33].to_a.map(&:to_i).to_s

    min_shanten = @agari_number_table.map do |numbers|
      manzu_number = numbers[0].to_s
      pinzu_number = numbers[1].to_s
      souzu_number = numbers[2].to_s
      zihai_number = numbers[3].to_s

      manzu_shanten = @shanten_list['suuhai'][manzu_code][manzu_number]
      pinzu_shanten = @shanten_list['suuhai'][pinzu_code][pinzu_number]
      souzu_shanten = @shanten_list['suuhai'][souzu_code][souzu_number]
      zihai_shanten = @shanten_list['zihai'][zihai_code][zihai_number]
      manzu_shanten + pinzu_shanten + souzu_shanten + zihai_shanten
    end.min
    min_shanten - 1
  end

  # codeの数を数えるため、順序の情報は失われる。
  def count_codes(tiles)
    code_counters = Array.new(34, 0)
    tiles.each { |tile| code_counters[tile.code] += 1 }
    code_counters
  end

  def count_outs(hand_tiles)
    return -1 if win?(hand_tiles)
    outs = 0

    (0..135).each do |id|
      tile = Tile.new(id)
      test_hand_tiles = hand_tiles.dup << tile
      test_codes = test_hand_tiles.map { |tile| tile.code }
      next unless test_codes.tally.all? { |_, tile_count| tile_count < 5 }
      outs += 1 if cal_shanten(test_hand_tiles) < cal_shanten(hand_tiles)
    end
    outs
  end

  def win?(hand_tiles)
    cal_shanten(hand_tiles) == -1
  end

  def game_over?
    @table.draw_count >= 122
  end

  def cal_reward(old_hands, new_hands)
    return 100 if win?
    return -100 if game_over?

    old_shanten = cal_shanten(old_hands)
    new_shanten = cal_shanten(new_hands)
    diff_shanten = new_shanten - old_shanten
    diff_outs = count_outs(new_hands) - count_outs(old_hands)

    return 50 if diff_shanten < 0
    return 50 if new_shanten == 0 && diff_outs > 0
    return 30 if new_shanten == 0 && diff_outs == 0
    return -10 if new_shanten == 0 && diff_outs < 0
    return 10 if diff_shanten == 0 && diff_outs > 0
    return -10 if diff_shanten == 0 && diff_outs == 0
    return -30 if diff_shanten == 0 && diff_outs < 0

    -50
  end

end
