# frozen_string_literal: true

require 'uri'

module Ihatov
  # Primitive dictionary-field validation, shared by schema checks.
  # @api private
  module Fields
    def mapping(value, allowed:, required: [])
      raise DataError, 'expected a mapping' unless value.is_a?(Hash)

      unknown = value.keys - allowed
      missing = required - value.keys
      raise DataError, "unknown keys: #{unknown.join(', ')}" unless unknown.empty?
      raise DataError, "missing required keys: #{missing.join(', ')}" unless missing.empty?

      value
    end

    def array(value, label)
      raise DataError, "#{label} must be an array" unless value.is_a?(Array)

      value
    end

    def string(value, label)
      raise DataError, "#{label} must be a nonempty string" unless value.is_a?(String) && !value.strip.empty?

      value
    end

    def identifier(value)
      string(value, 'id')
      raise DataError, "invalid id: #{value}" unless /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/.match?(value)

      value
    end

    def url(value, label)
      string(value, label)
      uri = URI.parse(value)
      raise DataError, "#{label} must be an absolute HTTP(S) URL" unless uri.is_a?(URI::HTTP) && uri.host
    rescue URI::InvalidURIError
      raise DataError, "invalid #{label}"
    end

    def year(value, label)
      return if value.nil? || (value.is_a?(Integer) && value.positive?)

      raise DataError, "#{label} must be a positive integer or null"
    end

    def coordinate(value, label, range)
      return if value.is_a?(Numeric) && value.to_f.finite? && range.cover?(value)

      raise DataError, "invalid #{label}"
    end
  end
end
