# frozen_string_literal: true

module Ihatov
  # @api private
  module KenjiScope
    def scope
      { author_id: 'miyazawa-kenji' }
    end
  end

  # @api private
  module TakubokuScope
    def scope
      { author_id: 'ishikawa-takuboku' }
    end
  end

  # @api private
  module TonoScope
    def scope
      { work_id: 'tono-monogatari' }
    end
  end

  # Miyazawa Kenji's works. Query classes return the shared canonical values,
  # retaining all source relations even when another author also uses a place.
  module Kenji
    extend API

    # Kenji's quotations.
    class Quote < Ihatov::Quote
      extend KenjiScope

      # Kenji's poems.
      class Poem < Ihatov::Quote::Poem
        extend KenjiScope
      end

      # Kenji's tanka.
      class Tanka < Ihatov::Quote::Tanka
        extend KenjiScope
      end

      # Kenji's haiku.
      class Haiku < Ihatov::Quote::Haiku
        extend KenjiScope
      end

      # Kenji's prose.
      class Passage < Ihatov::Quote::Passage
        extend KenjiScope
      end
    end

    # Kenji's works.
    class Work < Ihatov::Work
      extend KenjiScope
    end

    # Places associated with Kenji's works.
    class Place < Ihatov::Place
      extend KenjiScope
    end

    # All participants in Kenji's works.
    class Being < Ihatov::Being
      extend KenjiScope
    end

    # Human-shaped participants in Kenji's works.
    class Person < Ihatov::Person
      extend KenjiScope
    end

    # Nonhuman characters in Kenji's works.
    class Character < Ihatov::Character
      extend KenjiScope
    end

    # Creatures in Kenji's works.
    class Creature < Ihatov::Creature
      extend KenjiScope
    end

    # Onomatopoeias in Kenji's works.
    class Onomatopoeia < Ihatov::Onomatopoeia
      extend KenjiScope
    end
  end

  # Ishikawa Takuboku's works.
  module Takuboku
    extend API

    # Takuboku's quotations.
    class Quote < Ihatov::Quote
      extend TakubokuScope

      # Takuboku's poems.
      class Poem < Ihatov::Quote::Poem
        extend TakubokuScope
      end

      # Takuboku's tanka.
      class Tanka < Ihatov::Quote::Tanka
        extend TakubokuScope
      end

      # Takuboku's haiku.
      class Haiku < Ihatov::Quote::Haiku
        extend TakubokuScope
      end

      # Takuboku's prose.
      class Passage < Ihatov::Quote::Passage
        extend TakubokuScope
      end
    end

    # Takuboku's works.
    class Work < Ihatov::Work
      extend TakubokuScope
    end

    # Places associated with Takuboku's works.
    class Place < Ihatov::Place
      extend TakubokuScope
    end

    # All participants in Takuboku's works.
    class Being < Ihatov::Being
      extend TakubokuScope
    end

    # Human-shaped participants in Takuboku's works.
    class Person < Ihatov::Person
      extend TakubokuScope
    end

    # Nonhuman characters in Takuboku's works.
    class Character < Ihatov::Character
      extend TakubokuScope
    end

    # Creatures in Takuboku's works.
    class Creature < Ihatov::Creature
      extend TakubokuScope
    end

    # Onomatopoeias in Takuboku's works.
    class Onomatopoeia < Ihatov::Onomatopoeia
      extend TakubokuScope
    end
  end

  # The world of Tono Monogatari, not every work by Yanagita Kunio.
  module Tono
    extend API

    # Tono Monogatari's quotations.
    class Quote < Ihatov::Quote
      extend TonoScope

      # Poems associated with Tono Monogatari.
      class Poem < Ihatov::Quote::Poem
        extend TonoScope
      end

      # Tanka associated with Tono Monogatari.
      class Tanka < Ihatov::Quote::Tanka
        extend TonoScope
      end

      # Haiku associated with Tono Monogatari.
      class Haiku < Ihatov::Quote::Haiku
        extend TonoScope
      end

      # Tono Monogatari's prose.
      class Passage < Ihatov::Quote::Passage
        extend TonoScope
      end
    end

    # Tono Monogatari's work record.
    class Work < Ihatov::Work
      extend TonoScope
    end

    # Places associated with Tono Monogatari.
    class Place < Ihatov::Place
      extend TonoScope
    end

    # All participants in Tono Monogatari.
    class Being < Ihatov::Being
      extend TonoScope
    end

    # Human-shaped participants in Tono Monogatari.
    class Person < Ihatov::Person
      extend TonoScope
    end

    # Nonhuman characters in Tono Monogatari.
    class Character < Ihatov::Character
      extend TonoScope
    end

    # Creatures in Tono Monogatari.
    class Creature < Ihatov::Creature
      extend TonoScope
    end

    # Onomatopoeias in Tono Monogatari.
    class Onomatopoeia < Ihatov::Onomatopoeia
      extend TonoScope
    end
  end
end
