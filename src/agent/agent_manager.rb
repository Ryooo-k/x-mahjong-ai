# frozen_string_literal: true

require_relative 'discard_agent'
require_relative 'call_agent'

class AgentManager
  attr_reader :total_discard_loss, :total_call_loss

  def initialize(discard_agent_config, call_agent_config, riichi_agent_config, tsumo_agent_config, ron_agent_config)
    @discard_agent = DiscardAgent.new(discard_agent_config)
    @call_agent = CallAgent.new(call_agent_config)
    @riichi_agent = CallAgent.new(riichi_agent_config)
    @tsumo_agent = TsumoAgent.new(tsumo_agent_config)
    @ron_agent = RonAgent.new(ron_agent_config)
    @total_discard_loss = 0
    @total_call_loss = 0
    @total_riichi_loss = 0
    @total_tsumo_loss = 0
    @total_ron_loss = 0
  end

  def reset
    @total_discard_loss = 0
    @total_call_loss = 0
    @total_riichi_loss = 0
    @total_tsumo_loss = 0
    @total_ron_loss = 0
  end

  def get_discard_action(states)
    @discard_agent.get_action(states)
  end

  def get_call_action(states)
    @call_agent.get_action(states)
  end

  def get_riichi_action(states)
    @riichi_agent.get_action(states)
  end

  def get_tsumo_action(states)
    @tsumo_agent.get_action(states)
  end

  def get_ron_action(states)
    @ron_agent.get_action(states)
  end

  def update_discard_agent(state, action, reward, next_state, done)
    loss = @discard_agent.update(state, action, reward, next_state, done)
    @total_discard_loss += loss
  end

  def update_call_agent(state, action, reward, next_state, done)
    loss = @call_agent.update(state, action, reward, next_state, done)
    @total_call_loss += loss
  end

  def update_riichi_agent(state, action, reward, next_state, done)
    loss = @riichi_agent.update(state, action, reward, next_state, done)
    @total_riichi_loss += loss
  end

  def update_tsumo_agent(state, action, reward, next_state, done)
    loss = @tsumo_agent.update(state, action, reward, next_state, done)
    @total_tsumo_loss += loss
  end

  def update_ron_agent(state, action, reward, next_state, done)
    loss = @ron_agent.update(state, action, reward, next_state, done)
    @total_ron_loss += loss
  end

  def sync_qnet
    @discard_agent.sync_qnet
    @call_agent.sync_qnet
    @riichi_agent.sync_qnet
    @tsumo_agent.sync_qnet
    @ron_agent.sync_qnet
  end
end
