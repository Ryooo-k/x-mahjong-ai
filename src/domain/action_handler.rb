# frozen_string_literal: true

require_relative 'action_manager'
require_relative 'logic/hand_evaluator'
require_relative '../environment/reward_calculator'
require_relative '../environment/state_builder'

module Domain
  module ActionHandler
    HandEvaluator = Domain::Logic::HandEvaluator

    class << self
      def handle_tsumo_action(current_player, other_players, table, states)
        mask = StateBuilder.build_tsumo_action_mask(current_player, table.round[:wind])
        action = current_player.agent.get_action(states, mask)
        pass = ActionManager::PASS_INDEX

        if action == ActionManager::TSUMO_INDEX
          current_player.record_hand_status
          received_point, paid_by_host, paid_by_child = HandEvaluator.calculate_point(current_player, table, true)
          current_player.award_point(received_point)
          other_players.each { |player| table.host == player ? player.award_point(paid_by_host) : player.award_point(paid_by_child) }
        end

        [action, pass, pass, pass]
      end

      def handle_discard_action(current_player, other_players, table, states)
        mask = StateBuilder.build_discard_action_mask(current_player)
        action = current_player.agent.get_action(states, mask)
        target_tile = current_player.choose(action)
        current_player.discard(target_tile)
        current_player.record_hand_status
        [action, target_tile]
      end

      def handle_ron_action(current_player, other_players, table, discarded_tile)
        ron_player = get_ron_action(other_players, table.round[:wind], discarded_tile)

        if ron_player
          is_tsumo = false
          point, *_ = HandEvaluator.calculate_point(ron_player, table, is_tsumo)
          ron_player.award_point(point)
          current_player.award_point(-point)
          other_players.each { |player| player.award_point(0) if player != ron_player }
        end
        ron_player
      end

      private

      def get_ron_action(other_players, round_wind, tile)
        ron_player = nil

        other_players.each do |player|
          if player.can_ron?(tile, round_wind)
            player.draw(tile)
            player.record_hand_status
            ron_player = player
          end
          break if !ron_player.nil?
        end
        ron_player
      end
    end
  end
end
