# frozen_string_literal: true

require_relative '../util/tile_definitions'

class Tile
  attr_reader :id, :code, :name, :number, :suit
  attr_accessor :holder

  MAX_TILE_ID = 135

  def initialize(id)
    raise ArgumentError, '無効なIDです。' unless (0..MAX_TILE_ID).to_a.include?(id)

    @id = id
    @code = TILE_DEFINITIONS[id][:code]
    @name = TILE_DEFINITIONS[id][:name]
    @number = TILE_DEFINITIONS[id][:number]
    @suit = TILE_DEFINITIONS[id][:suit]
    @holder = nil
  end

  def reset
    @holder = nil
  end
end
