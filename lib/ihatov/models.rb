# frozen_string_literal: true

module Ihatov
  # A frozen author name, composed from the dictionary's separate name fields.
  class Author < String
    # @return [String] stable identifier
    attr_reader :id
    # @return [String] surname
    attr_reader :family_name
    # @return [String] given name
    attr_reader :given_name

    # @api private
    def initialize(id:, family_name:, given_name:)
      @id = id.dup.freeze
      @family_name = family_name.dup.freeze
      @given_name = given_name.dup.freeze
      super("#{family_name} #{given_name}")
      freeze
    end

    # @return [Author] frozen full name separated by one ASCII space
    def name
      self
    end
  end

  # The single Aozora edition adopted for a work.
  class Edition
    # @return [Integer] Aozora work-card identifier
    attr_reader :aozora_id
    # @return [String] Aozora work-card URL
    attr_reader :url
    # @return [String] transcribed source-volume information
    attr_reader :bibliography

    # @api private
    def initialize(aozora_id:, url:, bibliography:)
      @aozora_id = aozora_id
      @url = url.dup.freeze
      @bibliography = bibliography.dup.freeze
      freeze
    end
  end

  # A work's title, author, chronology, and adopted edition.
  class Work < String
    extend Collection
    extend NamedLookup

    # @return [String] stable identifier
    attr_reader :id
    # @return [Author] author
    attr_reader :author
    # @return [Edition] adopted edition
    attr_reader :edition
    # @return [Integer, nil] first announcement year
    attr_reader :announced_year
    # @return [Integer, nil] publication year (fallback for ordering)
    attr_reader :published_year
    # @api private
    attr_reader :sort_key

    # @api private
    def self.category
      :works
    end

    # @api private
    def initialize(id:, title:, author:, edition:, order:, announced_year: nil, published_year: nil)
      @id = id.dup.freeze
      @author = author
      @edition = edition
      @announced_year = announced_year
      @published_year = published_year
      @sort_key = [announced_year || published_year || Float::INFINITY, order].freeze
      super(title)
      freeze
    end

    # @return [Work] frozen title
    def title
      self
    end
  end

  # One relation to a source work, with its own location and URL.
  class Source
    # @return [Work] source work
    attr_reader :work
    # @return [String, nil] human-readable location, e.g. a chapter or tale number
    attr_reader :location
    # @return [String] explicit URL, or the work's edition URL
    attr_reader :source_url

    # @api private
    def initialize(work:, location: nil, source_url: nil)
      @work = work
      @location = location&.dup&.freeze
      @source_url = (source_url || work.edition.url).dup.freeze
      freeze
    end
  end

  # Shared immutable metadata for dictionary strings.
  # @api private
  class Value < String
    extend Collection

    # @return [String] stable manual identifier within this category
    attr_reader :id
    # @return [Array<Work>] frozen unique works, in chronological order
    attr_reader :works
    # @return [Array<Source>] frozen per-work source relations
    attr_reader :sources

    def initialize(value, id:, sources:)
      @id = id.dup.freeze
      @sources = sources.each_with_index.sort_by { |source, index| [*source.work.sort_key, index] }
                        .map(&:first).freeze
      @works = @sources.map(&:work).uniq(&:id).freeze
      super(value)
      freeze
    end

    # @return [Work] first related work in chronological order
    def work
      works.first
    end

    # @return [String, nil] location of the first source
    def location
      sources.first.location
    end

    # @return [String] URL of the first source
    def source_url
      sources.first.source_url
    end
  end

  # A real or fictional place. Places do not have content warnings.
  class Place < Value
    extend NamedLookup

    # @return [Boolean] real-world place, independently of available coordinates
    attr_reader :real
    # @return [Hash{Symbol => Float}, nil] frozen WGS 84 latitude and longitude
    attr_reader :coordinates

    # @api private
    def self.category
      :places
    end

    # @api private
    def initialize(name, real:, coordinates: nil, **metadata)
      @real = real
      @coordinates = coordinates&.dup&.freeze
      super(name, **metadata)
    end

    # @return [Place] frozen name
    def name
      self
    end
  end

  # Warnings are authored in the dictionary; no network moderation is performed.
  # @api private
  class WarnedValue < Value
    # @return [Array<String>] frozen explanations, empty if none
    attr_reader :content_warnings

    def initialize(value, content_warnings: [], **metadata)
      @content_warnings = content_warnings.map { |warning| warning.dup.freeze }.freeze
      super(value, **metadata)
    end
  end

  # Literary quotations, excluding standalone onomatopoeias.
  class Quote < WarnedValue
    # @api private
    def self.category
      :quotes
    end

    # @return [Quote] frozen quotation
    def text
      self
    end

    # @return [Symbol] literary form
    def kind
      self.class.kind
    end

    # @param options [Hash] poem filters and optional random generator
    # @return [Quote::Poem] frozen poem
    def self.poem(**options)
      self::Poem.sample(**options)
    end

    # @param options [Hash] filters and optional random generator
    # @return [Quote::Tanka] frozen complete tanka
    def self.tanka(**options)
      self::Tanka.sample(**options)
    end

    # @param options [Hash] filters and optional random generator
    # @return [Quote::Haiku] frozen complete haiku
    def self.haiku(**options)
      self::Haiku.sample(**options)
    end

    # @param options [Hash] filters and optional random generator
    # @return [Quote::Passage] frozen prose excerpt
    def self.passage(**options)
      self::Passage.sample(**options)
    end

    # A poem excerpt whose canonical indentation is two spaces per level.
    class Poem < Quote
      # @api private
      def self.kind
        :poem
      end

      # @api private
      def initialize(text, original_text: text, **metadata)
        @original_text = original_text.dup.freeze
        super(text, **metadata)
      end

      # @return [Boolean] whether the canonical text includes indented lines
      def indented?
        @original_text.lines.any? { |line| line.start_with?('  ') }
      end

      # Reformat from the original levels, preserving interior spaces and sources.
      # @param unit [String] nonempty sequence of ASCII spaces and/or tabs per level
      # @return [Poem] new frozen poem; no sampling and no mutation
      # @raise [ArgumentError] unless unit consists of spaces or tabs
      # @example
      #   Ihatov.poem(indent: true).with_indent("\t")
      def with_indent(unit)
        unless unit.is_a?(String) && /\A[ \t]+\z/.match?(unit)
          raise ArgumentError, 'indent must contain only spaces or tabs and not be empty'
        end

        formatted = @original_text.gsub(/^ +/) { |spaces| unit * (spaces.length / 2) }
        self.class.new(formatted, original_text: @original_text, id: id,
                                  sources: sources, content_warnings: content_warnings)
      end
    end

    # One complete tanka.
    class Tanka < Quote
      # @api private
      def self.kind
        :tanka
      end
    end

    # One complete haiku.
    class Haiku < Quote
      # @api private
      def self.kind
        :haiku
      end
    end

    # A selected prose excerpt.
    class Passage < Quote
      # @api private
      def self.kind
        :passage
      end
    end
  end

  # A story's participant, including animals, objects, and supernatural beings.
  class Being < WarnedValue
    extend NamedLookup

    # @api private
    def self.category
      :beings
    end

    # @return [Being] frozen name
    def name
      self
    end

    # @return [Symbol] dictionary-defined classification
    def kind
      self.class.kind
    end
  end

  # A human or basically human-shaped participant.
  class Person < Being
    # @api private
    def self.kind
      :person
    end
  end

  # A participant based on a nonhuman animal, plant, or object.
  class Character < Being
    # @api private
    def self.kind
      :character
    end
  end

  # A supernatural, unusual, or unidentified being.
  class Creature < Being
    # @api private
    def self.kind
      :creature
    end
  end

  # A standalone onomatopoeic or mimetic phrase.
  class Onomatopoeia < WarnedValue
    # @api private
    def self.category
      :onomatopoeias
    end

    # @return [Onomatopoeia] frozen text
    def text
      self
    end
  end
end
