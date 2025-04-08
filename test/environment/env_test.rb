# frozen_string_literal: true

require 'test/unit'
require_relative '../../src/environment/env'

class EnvTest < Test::Unit::TestCase
  def test_cal_shanten
    # binding.break
    hands = [1,2,3,4,5,6,7,8,9,10,10,15,17]
    env = MahjongEnv.new("", hands)
    shanten = env.cal_shanten(hands)
    assert_equal 1, shanten
  end
end
