# frozen_string_literal: true

require 'yaml'
require 'uri'

module Ihatov
  # Strict, safe YAML loading including duplicate-key detection.
  # @api private
  module DictionaryYAML
    def self.read(path)
      content = File.read(path, encoding: 'UTF-8')
      tree = Psych.parse_stream(content, filename: path)
      raise DataError, "#{path}: expected one YAML document" unless tree.children.size == 1

      check_keys(tree)
      YAML.safe_load(content, permitted_classes: [], permitted_symbols: [], aliases: false, filename: path)
    rescue Psych::Exception, SystemCallError => e
      raise DataError, "#{path}: #{e.message}"
    end

    def self.check_keys(node)
      if node.is_a?(Psych::Nodes::Mapping)
        names = []
        node.children.each_slice(2) do |key, value|
          raise DataError, 'YAML keys must be scalar strings' unless key.is_a?(Psych::Nodes::Scalar)
          raise DataError, "duplicate YAML key: #{key.value}" if names.include?(key.value)

          names << key.value
          check_keys(value)
        end
      else
        (node.children || []).each { |child| check_keys(child) }
      end
    end
  end

  # Validation for dictionary fields, independent of public query arguments.
  # @api private
  module Schema
    CATEGORIES = %w[quotes places beings onomatopoeias].freeze
    SOURCE_KEYS = %w[location source_url].freeze
    ITEM_KEYS = {
      'quotes' => %w[id kind text content_warnings],
      'places' => %w[id name real coordinates],
      'beings' => %w[id kind name content_warnings],
      'onomatopoeias' => %w[id text content_warnings]
    }.transform_values(&:freeze).freeze

    def self.mapping(value, allowed:, required: [])
      raise DataError, 'expected a mapping' unless value.is_a?(Hash)

      unknown = value.keys - allowed
      missing = required - value.keys
      raise DataError, "unknown keys: #{unknown.join(', ')}" unless unknown.empty?
      raise DataError, "missing required keys: #{missing.join(', ')}" unless missing.empty?

      value
    end

    def self.array(value, label)
      raise DataError, "#{label} must be an array" unless value.is_a?(Array)

      value
    end

    def self.string(value, label)
      raise DataError, "#{label} must be a nonempty string" unless value.is_a?(String) && !value.strip.empty?

      value
    end

    def self.identifier(value)
      string(value, 'id')
      raise DataError, "invalid id: #{value}" unless /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/.match?(value)

      value
    end

    def self.url(value, label)
      string(value, label)
      uri = URI.parse(value)
      raise DataError, "#{label} must be an absolute HTTP(S) URL" unless uri.is_a?(URI::HTTP) && uri.host
    rescue URI::InvalidURIError
      raise DataError, "invalid #{label}"
    end

    def self.year(value, label)
      return if value.nil? || (value.is_a?(Integer) && value.positive?)

      raise DataError, "#{label} must be a positive integer or null"
    end

    def self.author(row)
      mapping(row, allowed: %w[id family_name given_name], required: %w[id family_name given_name])
      identifier(row['id'])
      string(row['family_name'], 'family_name')
      string(row['given_name'], 'given_name')
    end

    def self.work(row)
      keys = %w[id title edition announced_year published_year] + CATEGORIES
      mapping(row, allowed: keys, required: %w[id title edition])
      identifier(row['id'])
      string(row['title'], 'title')
      year(row['announced_year'], 'announced_year')
      year(row['published_year'], 'published_year')
      edition(row['edition'])
      CATEGORIES.each { |category| array(row.fetch(category, []), category) }
    end

    def self.edition(row)
      keys = %w[aozora_id url bibliography]
      mapping(row, allowed: keys, required: keys)
      unless row['aozora_id'].is_a?(Integer) && row['aozora_id'].positive?
        raise DataError, 'aozora_id must be a positive integer'
      end

      url(row['url'], 'edition.url')
      string(row['bibliography'], 'bibliography')
    end

    def self.item(row, category)
      raise DataError, 'expected an item mapping' unless row.is_a?(Hash)

      if row.key?('ref')
        mapping(row, allowed: ['ref'] + SOURCE_KEYS, required: ['ref'])
        identifier(row['ref'])
      else
        keys = ITEM_KEYS.fetch(category)
        mapping(row, allowed: keys + SOURCE_KEYS, required: keys - %w[coordinates content_warnings])
        identifier(row['id'])
        validate_value(row, category)
      end
      string(row['location'], 'location') unless row['location'].nil?
      url(row['source_url'], 'source_url') unless row['source_url'].nil?
    end

    def self.validate_value(row, category)
      case category
      when 'places'
        string(row['name'], 'name')
        place(row)
      when 'beings'
        string(row['name'], 'name')
        raise DataError, 'invalid being kind' unless %w[person character creature].include?(row['kind'])
      when 'quotes'
        raise DataError, 'invalid quote kind' unless %w[poem tanka haiku passage].include?(row['kind'])

        text(row['text'])
        poem(row['text']) if row['kind'] == 'poem'
      when 'onomatopoeias'
        text(row['text'])
        raise DataError, 'onomatopoeia spaces must be ASCII' if /[\t　]/.match?(row['text'])
      end
      return if category == 'places'

      array(row.fetch('content_warnings', []), 'content_warnings').each { |value| string(value, 'warning') }
    end

    def self.text(value)
      string(value, 'text')
      raise DataError, 'text must use LF, without a trailing newline' if value.include?("\r") || value.end_with?("\n")
    end

    def self.poem(value)
      value.lines.each do |line|
        prefix = line[/\A[ \t　]*/]
        next if /\A *\z/.match?(prefix) && prefix.length.even?

        raise DataError, 'poem indentation must use two ASCII spaces per level'
      end
    end

    def self.place(row)
      raise DataError, 'real must be true or false' unless [true, false].include?(row['real'])
      return if row['coordinates'].nil?
      raise DataError, 'fictional places cannot have coordinates' unless row['real']

      coords = mapping(row['coordinates'], allowed: %w[latitude longitude], required: %w[latitude longitude])
      coordinate(coords['latitude'], 'latitude', -90..90)
      coordinate(coords['longitude'], 'longitude', -180..180)
    end

    def self.coordinate(value, label, range)
      return if value.is_a?(Numeric) && value.to_f.finite? && range.cover?(value)

      raise DataError, "invalid #{label}"
    end
  end
end
