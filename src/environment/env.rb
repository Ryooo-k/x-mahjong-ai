require 'debug'
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

    if win?
      @done = true
      [state, 10000, @done]
    elsif game_over?
      @discarded << @hands.delete_at(action)
      @done = true
      [state, -50000, @done]
    else
      @discarded << @hands.delete_at(action)
      reward = cal_reward
      [state, reward, @done]
    end
  end

  def state(hands = @hands)
    states = convert_hands_to_states(hands)
    # discarded = @discarded.last.nil? ? -1 : @discarded.last

    states << cal_shanten(hands) / 8
    states << cal_diff_shanten
    states << @wall_tiles.size / 136.0
    # states << discarded
    Torch.tensor(states, dtype: :float32)
  end

  def shanten(hands)
    cal_shanten(hands)
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

  #和了時の萬子、筒子、索子、字牌をそれぞれ何枚使用するかを指定するテーブル
  def build_agari_number_table
    number_table = [0, 2, 3, 5, 6, 8, 9, 11, 12, 14].repeated_permutation(4).filter { |n| n.sum == 14 }
    # 使用する各種牌数の合計が14であるかのチェックのみの場合、
    # [5, 2, 2, 5]などのあり得ないアガリ形が残るため、
    # 3で割った余りの合計が2以外の配列を除外する
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
    diff_shanten = cal_diff_shanten

    if diff_shanten > 0
    100
    elsif diff_shanten == 0
      -100
    else
      -200
    end
  end

  def cal_diff_shanten
    old_shanten = cal_shanten(@old_hands)
    new_shanten = cal_shanten(@hands)
    old_shanten - new_shanten
  end
end
