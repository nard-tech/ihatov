# frozen_string_literal: true

# Public entry points for Ihatov's literary dictionary.
module Ihatov
  # Convenience methods; all selection rules live in the collection classes.
  # @note Empty samples raise NotFoundError; invalid arguments raise ArgumentError.
  module API
    # @param options [Hash] filters and optional random generator (see Collection#sample)
    # @return [Quote] frozen quotation
    def quote(**options)
      self::Quote.sample(**options)
    end

    # @param options [Hash] filters; indent: true selects indented poems with two-space
    #   levels, false selects unindented poems, a String sets the indentation unit;
    #   omission includes all poems; random: accepts an independent Random
    # @return [Quote::Poem] frozen poem
    def poem(**options)
      self::Quote::Poem.sample(**options)
    end

    # @param options [Hash] filters and optional random generator
    # @return [Quote::Tanka] frozen complete tanka
    def tanka(**options)
      self::Quote::Tanka.sample(**options)
    end

    # @param options [Hash] filters and optional random generator
    # @return [Quote::Haiku] frozen complete haiku
    def haiku(**options)
      self::Quote::Haiku.sample(**options)
    end

    # @param options [Hash] filters and optional random generator
    # @return [Quote::Passage] frozen prose excerpt
    def passage(**options)
      self::Quote::Passage.sample(**options)
    end

    # @param options [Hash] filters and optional random generator
    # @return [Work] frozen work
    def work(**options)
      self::Work.sample(**options)
    end

    # @param options [Hash] filters and optional random generator
    # @return [Place] frozen place
    def place(**options)
      self::Place.sample(**options)
    end

    # @param options [Hash] filters and optional random generator
    # @return [Person] frozen human or human-shaped participant
    def person(**options)
      self::Person.sample(**options)
    end

    # @param options [Hash] filters and optional random generator
    # @return [Character] frozen nonhuman participant
    def character(**options)
      self::Character.sample(**options)
    end

    # @param options [Hash] filters and optional random generator
    # @return [Creature] frozen creature
    def creature(**options)
      self::Creature.sample(**options)
    end

    # @param options [Hash] filters and optional random generator
    # @return [Onomatopoeia] frozen standalone phrase, not a quotation
    def onomatopoeia(**options)
      self::Onomatopoeia.sample(**options)
    end
  end

  extend API
end
