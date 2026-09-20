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

  # 宮沢賢治の作品。検索クラスは、すべての関連出典を保持した共通の値を返す。
  # Miyazawa Kenji's works. Query classes return the shared canonical values,
  # retaining all source relations even when another author also uses a place.
  module Kenji
    extend API

    # 賢治の抜粋。
    # Kenji's quotations.
    class Quote < Ihatov::Quote
      extend KenjiScope

      # 賢治の詩。
      # Kenji's poems.
      class Poem < Ihatov::Quote::Poem
        extend KenjiScope
      end

      # 賢治の短歌。
      # Kenji's tanka.
      class Tanka < Ihatov::Quote::Tanka
        extend KenjiScope
      end

      # 賢治の俳句。
      # Kenji's haiku.
      class Haiku < Ihatov::Quote::Haiku
        extend KenjiScope
      end

      # 賢治の散文。
      # Kenji's prose.
      class Passage < Ihatov::Quote::Passage
        extend KenjiScope
      end
    end

    # 賢治の作品。
    # Kenji's works.
    class Work < Ihatov::Work
      extend KenjiScope
    end

    # 賢治の作品に関連する地名。
    # Places associated with Kenji's works.
    class Place < Ihatov::Place
      extend KenjiScope
    end

    # 賢治の作品の登場者全体。
    # All participants in Kenji's works.
    class Being < Ihatov::Being
      extend KenjiScope
    end

    # 賢治の作品の人間の姿をした登場者。
    # Human-shaped participants in Kenji's works.
    class Person < Ihatov::Person
      extend KenjiScope
    end

    # 賢治の作品の人間以外の登場者。
    # Nonhuman characters in Kenji's works.
    class Character < Ihatov::Character
      extend KenjiScope
    end

    # 賢治の作品の異形・正体不明の存在。
    # Creatures in Kenji's works.
    class Creature < Ihatov::Creature
      extend KenjiScope
    end

    # 賢治の作品の擬音語・擬態語。
    # Onomatopoeias in Kenji's works.
    class Onomatopoeia < Ihatov::Onomatopoeia
      extend KenjiScope
    end
  end

  # 石川啄木の作品。
  # Ishikawa Takuboku's works.
  module Takuboku
    extend API

    # 啄木の抜粋。
    # Takuboku's quotations.
    class Quote < Ihatov::Quote
      extend TakubokuScope

      # 啄木の詩。
      # Takuboku's poems.
      class Poem < Ihatov::Quote::Poem
        extend TakubokuScope
      end

      # 啄木の短歌。
      # Takuboku's tanka.
      class Tanka < Ihatov::Quote::Tanka
        extend TakubokuScope
      end

      # 啄木の俳句。
      # Takuboku's haiku.
      class Haiku < Ihatov::Quote::Haiku
        extend TakubokuScope
      end

      # 啄木の散文。
      # Takuboku's prose.
      class Passage < Ihatov::Quote::Passage
        extend TakubokuScope
      end
    end

    # 啄木の作品。
    # Takuboku's works.
    class Work < Ihatov::Work
      extend TakubokuScope
    end

    # 啄木の作品に関連する地名。
    # Places associated with Takuboku's works.
    class Place < Ihatov::Place
      extend TakubokuScope
    end

    # 啄木の作品の登場者全体。
    # All participants in Takuboku's works.
    class Being < Ihatov::Being
      extend TakubokuScope
    end

    # 啄木の作品の人間の姿をした登場者。
    # Human-shaped participants in Takuboku's works.
    class Person < Ihatov::Person
      extend TakubokuScope
    end

    # 啄木の作品の人間以外の登場者。
    # Nonhuman characters in Takuboku's works.
    class Character < Ihatov::Character
      extend TakubokuScope
    end

    # 啄木の作品の異形・正体不明の存在。
    # Creatures in Takuboku's works.
    class Creature < Ihatov::Creature
      extend TakubokuScope
    end

    # 啄木の作品の擬音語・擬態語。
    # Onomatopoeias in Takuboku's works.
    class Onomatopoeia < Ihatov::Onomatopoeia
      extend TakubokuScope
    end
  end

  # 『遠野物語』の世界。柳田國男の全作品を対象とするものではない。
  # The world of Tono Monogatari, not every work by Yanagita Kunio.
  module Tono
    extend API

    # 『遠野物語』の抜粋。
    # Tono Monogatari's quotations.
    class Quote < Ihatov::Quote
      extend TonoScope

      # 『遠野物語』に関連する詩。
      # Poems associated with Tono Monogatari.
      class Poem < Ihatov::Quote::Poem
        extend TonoScope
      end

      # 『遠野物語』に関連する短歌。
      # Tanka associated with Tono Monogatari.
      class Tanka < Ihatov::Quote::Tanka
        extend TonoScope
      end

      # 『遠野物語』に関連する俳句。
      # Haiku associated with Tono Monogatari.
      class Haiku < Ihatov::Quote::Haiku
        extend TonoScope
      end

      # 『遠野物語』の散文。
      # Tono Monogatari's prose.
      class Passage < Ihatov::Quote::Passage
        extend TonoScope
      end
    end

    # 『遠野物語』の作品情報。
    # Tono Monogatari's work record.
    class Work < Ihatov::Work
      extend TonoScope
    end

    # 『遠野物語』に関連する地名。
    # Places associated with Tono Monogatari.
    class Place < Ihatov::Place
      extend TonoScope
    end

    # 『遠野物語』の登場者全体。
    # All participants in Tono Monogatari.
    class Being < Ihatov::Being
      extend TonoScope
    end

    # 『遠野物語』の人間の姿をした登場者。
    # Human-shaped participants in Tono Monogatari.
    class Person < Ihatov::Person
      extend TonoScope
    end

    # 『遠野物語』の人間以外の登場者。
    # Nonhuman characters in Tono Monogatari.
    class Character < Ihatov::Character
      extend TonoScope
    end

    # 『遠野物語』の異形・正体不明の存在。
    # Creatures in Tono Monogatari.
    class Creature < Ihatov::Creature
      extend TonoScope
    end

    # 『遠野物語』の擬音語・擬態語。
    # Onomatopoeias in Tono Monogatari.
    class Onomatopoeia < Ihatov::Onomatopoeia
      extend TonoScope
    end
  end
end
