# frozen_string_literal: true

require_relative '../agent/discard_agent'
require_relative '../agent/call_agent'

class PlayerAgent
  def initialize(config)
    @discard = DiscardAgent.new(config[:discard_agent])
    @call = CallAgent.new(config[:call_agent])
  end

  def get_discard_action
    @discard.get_action
  end

  def get_call_action
    @call.get_action
  end
end
