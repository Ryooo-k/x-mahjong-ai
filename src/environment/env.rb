# frozen_string_literal: true

require 'json'

class MahjongEnv
  attr_reader :wall_tiles, :hands, :done, :order, :shanten_list

  def initialize(shanten_list)
    @wall_tiles = build_wall_tiles
    @hands = @wall_tiles.shift(13)
    @old_hands = @hands.dup
    @discarded = []
    @done = false
    @order = 0
    @shanten_list = shanten_list
    @agari_number_table = build_agari_number_table
  end

  def tumo
    @old_hands = @hands.dup
    @hands << @wall_tiles.shift
  end

  def step(action)
    return nil if @done
    @order += 1
    @done = true if win? || game_over?
    play_tile(action) unless win?
    reward = cal_reward
    [state, reward, @done]
  end

  def state(hands = @hands)
    states = convert_hands_to_states(hands)

    states << cal_shanten(hands) / 8
    states << cal_diff_shanten
    states << @wall_tiles.size / 136.0
    states << count_outs(hands) / 34.0
    Torch.tensor(states, dtype: :float32)
  end

  def shanten(hands = @hands)
    cal_shanten(hands)
  end

  def render
    # 後で実装する
  end

  private

  def convert_hands_to_states(hands)
    states = Array.new(34, 0.0)
    hands.each { |tile| states[tile] += 1 }
    states
  end

  def build_wall_tiles
    tiles = [*(0..33)] * 4
    tiles.shuffle
  end

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

  def win?
    cal_shanten(@hands) == -1
  end

  def game_over?
    @wall_tiles.size < 12
  end

  def cal_shanten(hands)
    states = convert_hands_to_states(hands)
    manzu_state = states[0..8].to_a.map(&:to_i).to_s
    pinzu_state = states[9..17].to_a.map(&:to_i).to_s
    souzu_state = states[18..26].to_a.map(&:to_i).to_s
    zihai_state = states[27..33].to_a.map(&:to_i).to_s

    min_shanten = @agari_number_table.map do |numbers|
      manzu_number = numbers[0].to_s
      pinzu_number = numbers[1].to_s
      souzu_number = numbers[2].to_s
      zihai_number = numbers[3].to_s

      manzu_shanten = @shanten_list['suuhai'][manzu_state][manzu_number]
      pinzu_shanten = @shanten_list['suuhai'][pinzu_state][pinzu_number]
      souzu_shanten = @shanten_list['suuhai'][souzu_state][souzu_number]
      zihai_shanten = @shanten_list['zihai'][zihai_state][zihai_number]
      manzu_shanten + pinzu_shanten + souzu_shanten + zihai_shanten
    end.min

    min_shanten - 1
  end

  def cal_reward
    return 100 if win?
    return -100 if game_over?

    old_shanten = cal_shanten(@old_hands)
    new_shanten = cal_shanten(@hands)
    diff_shanten = new_shanten - old_shanten
    diff_outs = count_outs(@hands) - count_outs(@old_hands)

    return 50 if diff_shanten < 0
    return 50 if new_shanten == 0 && diff_outs > 0
    return 30 if new_shanten == 0 && diff_outs == 0
    return -10 if new_shanten == 0 && diff_outs < 0
    return 10 if diff_shanten == 0 && diff_outs > 0
    return -10 if diff_shanten == 0 && diff_outs == 0
    return -30 if diff_shanten == 0 && diff_outs < 0

    -50
  end

  def cal_diff_shanten
    old_shanten = cal_shanten(@old_hands)
    new_shanten = cal_shanten(@hands)
    old_shanten - new_shanten
  end

  def count_outs(hands)
    return -1 if win?
    outs = 0

    (0..33).each do |tile|
      test_hands = hands.dup << tile
      next unless test_hands.tally.all? { |_, tile_count| tile_count < 5 }
      outs += 1 if cal_shanten(test_hands) < cal_shanten(hands)
    end
    outs
  end

  def play_tile(action)
    played_tile = @hands.sort[action]
    index = @hands.index(played_tile)
    @discarded << @hands.delete_at(index)
  end
end
