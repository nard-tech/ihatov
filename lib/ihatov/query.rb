# frozen_string_literal: true

module Ihatov
  # Collection methods shared by the explicit public query classes.
  module Collection
    # All entries in chronological order, without sampling.
    # @return [Array<String>] frozen array of frozen values
    def all
      where
    end

    # Match conditions with AND, retaining the namespace's scope.
    # @param conditions [Hash] author, work, and category-specific filters
    # @option conditions [Author, String] :author registered author name or object
    # @option conditions [Work, String] :work registered title or object
    # @option conditions [Boolean] :real only for places
    # @option conditions [Boolean, String] :indent only for poems; true selects
    #   indented poems, false selects others, a string also formats indentation
    # @option conditions [Boolean] :exclude_content_warnings (false) omit warned entries
    # @return [Array<String>] frozen array; no matches returns an empty array
    # @raise [ArgumentError] if a filter is unsupported or malformed
    def where(**conditions)
      Query.new(self, conditions).all
    end

    # Select uniformly from the matching entries, not from authors.
    # @param random [Random] generator; defaults to Ihatov's shared generator
    # @param conditions [Hash] same filters as {#where}
    # @return [String] frozen metadata-bearing String subclass
    # @raise [ArgumentError] for invalid arguments
    # @raise [NotFoundError] when no entries match
    def sample(random: Ihatov.random_generator, **conditions)
      raise ArgumentError, 'random must be a Random' unless random.is_a?(Random)

      Query.new(self, conditions).sample(random)
    end

    # @api private
    def kind
      nil
    end

    # @api private
    def scope
      {}
    end
  end

  # Exact-name lookup for named entities (not quotations).
  module NamedLookup
    # @param name [String] exact registered title or name, without normalization
    # @param conditions [Hash] same filters as where
    # @return [String] first matching frozen value in chronological order
    # @raise [ArgumentError] for invalid arguments
    # @raise [NotFoundError] if the name is not registered in this scope
    def find(name, **conditions)
      raise ArgumentError, 'name must be a String' unless name.is_a?(String)

      where(**conditions).find { |item| item == name } || raise(NotFoundError, "not found: #{name}")
    end
  end

  # Filters before sampling and formats only the selected result.
  # @api private
  class Query
    def initialize(collection, conditions)
      @collection = collection
      @conditions = conditions
      validate!
    end

    def all
      candidates.map { |item| format(item) }.freeze
    end

    def sample(random)
      item = candidates.sample(random: random)
      raise NotFoundError, 'no entries match the requested conditions' unless item

      format(item)
    end

    private

    def validate!
      allowed = %i[author work]
      allowed << :real if @collection.category == :places
      allowed << :indent if @collection.kind == :poem
      allowed << :exclude_content_warnings if %i[quotes beings onomatopoeias].include?(@collection.category)
      unknown = @conditions.keys - allowed
      raise ArgumentError, "unsupported conditions: #{unknown.join(', ')}" unless unknown.empty?

      validate_values!
    end

    def validate_values!
      @conditions.each do |key, value|
        valid = case key
                when :author then value.is_a?(Author) || value.is_a?(String)
                when :work then value.is_a?(Work) || value.is_a?(String)
                when :real, :exclude_content_warnings then [true, false].include?(value)
                when :indent then [true, false].include?(value) || valid_indent?(value)
                end
        raise ArgumentError, "invalid #{key}: #{value.inspect}" unless valid
      end
    end

    def valid_indent?(value)
      value.is_a?(String) && /\A[ \t]+\z/.match?(value)
    end

    def candidates
      Ihatov.repository.items(@collection.category).select do |item|
        matches_kind?(item) && matches_work?(item) && matches_value?(item)
      end
    end

    def matches_kind?(item)
      @collection.kind.nil? || item.kind == @collection.kind
    end

    def matches_work?(item)
      works = item.is_a?(Work) ? [item] : item.works
      works.any? do |work|
        scope = @collection.scope
        (!scope[:author_id] || work.author.id == scope[:author_id]) &&
          (!scope[:work_id] || work.id == scope[:work_id]) &&
          matches_author?(work.author) && matches_title?(work)
      end
    end

    def matches_author?(author)
      filter = @conditions[:author]
      return true unless filter

      filter.is_a?(Author) ? author.id == filter.id : author.name == filter
    end

    def matches_title?(work)
      filter = @conditions[:work]
      return true unless filter

      filter.is_a?(Work) ? work.id == filter.id : work.title == filter
    end

    def matches_value?(item)
      return false if @conditions.key?(:real) && item.real != @conditions[:real]
      return false if @conditions[:exclude_content_warnings] && !item.content_warnings.empty?
      return true unless @conditions.key?(:indent)

      item.indented? == (@conditions[:indent] != false)
    end

    def format(item)
      indent = @conditions[:indent]
      indent.is_a?(String) ? item.with_indent(indent) : item
    end
  end
end
