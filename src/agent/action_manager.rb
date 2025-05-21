# frozen_string_literal: true

module ActionManager
  ACTIONS = [
    *(0..13).map { |i| :"discard_#{i}" },
    :pon, :chi, :ankan, :daiminkan, :kakan,
    :riichi, :ron, :tsumo, :pass
  ].freeze
  DISCARD_RANGE = (0..13)
  PON_INDEX = 14
  CHI_INDEX = 15
  ANKAN_INDEX = 16
  DAIMINKAN_INDEX = 17
  KAKAN_INDEX = 18
  RIICHI_INDEX = 19
  RON_INDEX = 20
  TSUMO_INDEX = 21
  PASS_INDEX = 22

  class << self
    def index(action_name)
      ACTIONS.index(action_name)
    end

    def name(index)
      ACTIONS[index]
    end

    def size
      ACTIONS.size
    end
  end
end
