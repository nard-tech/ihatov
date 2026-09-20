# frozen_string_literal: true

# Ihatovの文学辞書の公開API。
# Public entry points for Ihatov's literary dictionary.
module Ihatov
  # 取得用の便利なメソッド。選択規則はコレクションクラスが担う。
  # Convenience methods; all selection rules live in the collection classes.
  # @note 抽選候補がなければNotFoundError、不正な引数ならArgumentError。
  #   Empty samples raise NotFoundError; invalid arguments raise ArgumentError.
  module API
    # @param options [Hash] 絞り込み条件と任意の乱数生成器（Collection#sampleを参照）
    #   filters and optional random generator (see Collection#sample)
    # @return [Quote] 凍結された抜粋
    #   frozen quotation
    def quote(**options)
      self::Quote.sample(**options)
    end

    # @param options [Hash] 絞り込み条件。indent: trueは字下げ詩を半角2スペースで返す。
    #   falseは字下げのない詩、文字列は字下げ詩とその字下げ単位を指定する。
    #   省略時はすべての詩が対象。random:には独立したRandomを指定できる。
    #   Filters; indent: true selects indented poems with two-space
    #   levels, false selects unindented poems, a String sets the indentation unit;
    #   omission includes all poems; random: accepts an independent Random
    # @return [Quote::Poem] 凍結された詩
    #   frozen poem
    def poem(**options)
      self::Quote::Poem.sample(**options)
    end

    # @param options [Hash] 絞り込み条件と任意の乱数生成器
    #   filters and optional random generator
    # @return [Quote::Tanka] 凍結された短歌一首の全文
    #   frozen complete tanka
    def tanka(**options)
      self::Quote::Tanka.sample(**options)
    end

    # @param options [Hash] 絞り込み条件と任意の乱数生成器
    #   filters and optional random generator
    # @return [Quote::Haiku] 凍結された俳句一句の全文
    #   frozen complete haiku
    def haiku(**options)
      self::Quote::Haiku.sample(**options)
    end

    # @param options [Hash] 絞り込み条件と任意の乱数生成器
    #   filters and optional random generator
    # @return [Quote::Passage] 凍結された散文の抜粋
    #   frozen prose excerpt
    def passage(**options)
      self::Quote::Passage.sample(**options)
    end

    # @param options [Hash] 絞り込み条件と任意の乱数生成器
    #   filters and optional random generator
    # @return [Work] 凍結された作品
    #   frozen work
    def work(**options)
      self::Work.sample(**options)
    end

    # @param options [Hash] 絞り込み条件と任意の乱数生成器
    #   filters and optional random generator
    # @return [Place] 凍結された地名
    #   frozen place
    def place(**options)
      self::Place.sample(**options)
    end

    # @param options [Hash] 絞り込み条件と任意の乱数生成器
    #   filters and optional random generator
    # @return [Person] 凍結された人間または人間の姿をした登場者
    #   frozen human or human-shaped participant
    def person(**options)
      self::Person.sample(**options)
    end

    # @param options [Hash] 絞り込み条件と任意の乱数生成器
    #   filters and optional random generator
    # @return [Character] 凍結された人間以外の登場者
    #   frozen nonhuman participant
    def character(**options)
      self::Character.sample(**options)
    end

    # @param options [Hash] 絞り込み条件と任意の乱数生成器
    #   filters and optional random generator
    # @return [Creature] 凍結された異形・正体不明の存在
    #   frozen creature
    def creature(**options)
      self::Creature.sample(**options)
    end

    # @param options [Hash] 絞り込み条件と任意の乱数生成器
    #   filters and optional random generator
    # @return [Onomatopoeia] 凍結された単独の擬音語・擬態語
    #   frozen standalone phrase, not a quotation
    def onomatopoeia(**options)
      self::Onomatopoeia.sample(**options)
    end
  end

  extend API
end
