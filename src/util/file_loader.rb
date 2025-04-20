# frozen_string_literal: true

require 'json'
require 'yaml'

module Util
  module FileLoader
    def self.load_shanten_list
      path = File.expand_path('../data/shanten_list.json', __dir__)
      JSON.parse(File.read(path))
    end

    def self.load_parameter(target)
      path = File.expand_path('../../config/parameter.yml', __dir__)
      config = YAML.load_file(path)
      config[target]
    end
  end
end
