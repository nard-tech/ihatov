# frozen_string_literal: true

require_relative 'ihatov/version'

# 岩手の文学から、ひとこと。
module Ihatov
  # A single-value lookup or sample had no matching entries.
  class NotFoundError < StandardError; end

  # The bundled dictionary does not satisfy its schema.
  class DataError < StandardError; end

  # Reset the random generator shared by every Ihatov namespace.
  # @param value [Integer] seed (does not change Ruby's global RNG)
  # @return [Random]
  # @raise [ArgumentError] if value is not an Integer
  def self.seed=(value)
    raise ArgumentError, 'seed must be an Integer' unless value.is_a?(Integer)

    @random_generator = Random.new(value)
  end

  # @api private
  def self.random_generator
    @random_generator ||= Random.new
  end

  # @api private
  def self.repository
    @repository ||= Repository.load(File.expand_path('../data', __dir__))
  end
end

require_relative 'ihatov/query'
require_relative 'ihatov/models'
require_relative 'ihatov/schema'
require_relative 'ihatov/repository'
require_relative 'ihatov/api'
require_relative 'ihatov/namespaces'
