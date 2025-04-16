# frozen_string_literal: true

require 'json'
require 'yaml'

module FileLoader
  def self.load_parameter
    path = File.expand_path('../config/parameter.yml', __dir__)
    config = YAML.load_file(path)
    config['test_parameter']
  end
end
