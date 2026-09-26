# frozen_string_literal: true

require 'ihatov'
require 'tmpdir'
require 'yaml'

RSpec.configure do |config|
  config.before { Ihatov.seed = 1234 }
end
