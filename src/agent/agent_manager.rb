# frozen_string_literal: true

require_relative '../agent/discard_agent'
require_relative '../agent/call_agent'

class AgentManager
  def initialize(discard_agent_config, call_agent_config)
    @discard = DiscardAgent.new(discard_agent_config)
    @call = CallAgent.new(call_agent_config)
    @total_discard_loss = 0
    @total_call_loss = 0
  end

  def get_discard_action(states)
    @discard.get_action(states)
  end

  def get_call_action(states)
    @call.get_action(states)
  end

  def update_discard_agent(state, action, reward, next_state, done)
    loss = @discard.update(state, action, reward, next_state, done)
    @total_discard_loss += loss
  end

  def update_call_agent(state, action, reward, next_state, done)
    loss = @call_agent.update(state, action, reward, next_state, done)
    @total_call_loss += loss
  end

  def sync_qnet
    @discard.sync_qnet
    @call.sync_qnet
  end
end
