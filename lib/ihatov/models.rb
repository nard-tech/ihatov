# frozen_string_literal: true

module Ihatov
  # 辞書の姓と名から構成する、凍結された作者名。
  # A frozen author name, composed from the dictionary's separate name fields.
  class Author < String
    # @return [String] 固定の識別子
    #   stable identifier
    attr_reader :id
    # @return [String] 姓
    #   surname
    attr_reader :family_name
    # @return [String] 名
    #   given name
    attr_reader :given_name

    # @api private
    def initialize(id:, family_name:, given_name:)
      @id = id.dup.freeze
      @family_name = family_name.dup.freeze
      @given_name = given_name.dup.freeze
      super("#{family_name} #{given_name}")
      freeze
    end

    # @return [Author] 半角スペース一つで姓名を結合した凍結済みの名前
    #   frozen full name separated by one ASCII space
    def name
      self
    end
  end

  # 作品ごとに一つ選ぶ青空文庫の採用版。
  # The single Aozora edition adopted for a work.
  class Edition
    # @return [Integer] 青空文庫の作品ID
    #   Aozora work-card identifier
    attr_reader :aozora_id
    # @return [String] 青空文庫の図書カードURL
    #   Aozora work-card URL
    attr_reader :url
    # @return [String] 底本情報の転記
    #   transcribed source-volume information
    attr_reader :bibliography

    # @api private
    def initialize(aozora_id:, url:, bibliography:)
      @aozora_id = aozora_id
      @url = url.dup.freeze
      @bibliography = bibliography.dup.freeze
      freeze
    end
  end

  # 作品の題名・作者・年代・採用版。
  # A work's title, author, chronology, and adopted edition.
  class Work < String
    extend Collection
    extend NamedLookup

    # @return [String] 固定の識別子
    #   stable identifier
    attr_reader :id
    # @return [Author] 作者
    #   author
    attr_reader :author
    # @return [Edition] 採用版
    #   adopted edition
    attr_reader :edition
    # @return [Integer, nil] 初出の発表年
    #   first announcement year
    attr_reader :announced_year
    # @return [Integer, nil] 刊行年（発表年不明時の並び順に使用）
    #   publication year (fallback for ordering)
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

    # @return [Work] 凍結された題名
    #   frozen title
    def title
      self
    end
  end

  # 関連作品ごとの出典。位置情報とURLを保持する。
  # One relation to a source work, with its own location and URL.
  class Source
    # @return [Work] 出典の作品
    #   source work
    attr_reader :work
    # @return [String, nil] 章や話数など、人が読める位置情報
    #   human-readable location, e.g. a chapter or tale number
    attr_reader :location
    # @return [String] 指定されたURL、または採用版のURL
    #   explicit URL, or the work's edition URL
    attr_reader :source_url

    # @api private
    def initialize(work:, location: nil, source_url: nil)
      @work = work
      @location = location&.dup&.freeze
      @source_url = (source_url || work.edition.url).dup.freeze
      freeze
    end
  end

  # 辞書の文字列に共通する変更不可のメタデータ。
  # Shared immutable metadata for dictionary strings.
  # @api private
  class Value < String
    extend Collection

    # @return [String] 種別内で一意な、手動で定義する固定ID
    #   stable manual identifier within this category
    attr_reader :id
    # @return [Array<Work>] 重複のない関連作品を年代順に並べた凍結配列
    #   frozen unique works, in chronological order
    attr_reader :works
    # @return [Array<Source>] 作品ごとの出典関係を格納した凍結配列
    #   frozen per-work source relations
    attr_reader :sources

    def initialize(value, id:, sources:)
      @id = id.dup.freeze
      @sources = sources.each_with_index.sort_by { |source, index| [*source.work.sort_key, index] }
                        .map(&:first).freeze
      @works = @sources.map(&:work).uniq(&:id).freeze
      super(value)
      freeze
    end

    # @return [Work] 年代順で最初の関連作品
    #   first related work in chronological order
    def work
      works.first
    end

    # @return [String, nil] 先頭の出典の位置情報
    #   location of the first source
    def location
      sources.first.location
    end

    # @return [String] 先頭の出典のURL
    #   URL of the first source
    def source_url
      sources.first.source_url
    end
  end

  # 実在または架空の地名。注意情報は持たない。
  # A real or fictional place. Places do not have content warnings.
  class Place < Value
    extend NamedLookup

    # @return [Boolean] 実在する地名かどうか。座標の有無とは独立
    #   real-world place, independently of available coordinates
    attr_reader :real
    # @return [Hash{Symbol => Float}, nil] WGS 84の緯度・経度を格納した凍結ハッシュ
    #   frozen WGS 84 latitude and longitude
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

    # @return [Place] 凍結された名前
    #   frozen name
    def name
      self
    end
  end

  # 注意情報は辞書の編集時に付与する。通信による判定は行わない。
  # Warnings are authored in the dictionary; no network moderation is performed.
  # @api private
  class WarnedValue < Value
    # @return [Array<String>] 凍結された注意説明の配列。注意がなければ空配列
    #   frozen explanations, empty if none
    attr_reader :content_warnings

    def initialize(value, content_warnings: [], **metadata)
      @content_warnings = content_warnings.map { |warning| warning.dup.freeze }.freeze
      super(value, **metadata)
    end
  end

  # 文学作品の抜粋。単独の擬音語は含まない。
  # Literary quotations, excluding standalone onomatopoeias.
  class Quote < WarnedValue
    # @api private
    def self.category
      :quotes
    end

    # @return [Quote] 凍結された抜粋
    #   frozen quotation
    def text
      self
    end

    # @return [Symbol] 文章の種別
    #   literary form
    def kind
      self.class.kind
    end

    # @param options [Hash] 詩の絞り込み条件と任意の乱数生成器
    #   poem filters and optional random generator
    # @return [Quote::Poem] 凍結された詩
    #   frozen poem
    def self.poem(**options)
      self::Poem.sample(**options)
    end

    # @param options [Hash] 絞り込み条件と任意の乱数生成器
    #   filters and optional random generator
    # @return [Quote::Tanka] 凍結された短歌一首の全文
    #   frozen complete tanka
    def self.tanka(**options)
      self::Tanka.sample(**options)
    end

    # @param options [Hash] 絞り込み条件と任意の乱数生成器
    #   filters and optional random generator
    # @return [Quote::Haiku] 凍結された俳句一句の全文
    #   frozen complete haiku
    def self.haiku(**options)
      self::Haiku.sample(**options)
    end

    # @param options [Hash] 絞り込み条件と任意の乱数生成器
    #   filters and optional random generator
    # @return [Quote::Passage] 凍結された散文の抜粋
    #   frozen prose excerpt
    def self.passage(**options)
      self::Passage.sample(**options)
    end

    # 1段につき半角2スペースの字下げを原形とする詩の抜粋。
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

      # @return [Boolean] 原文に字下げのある行が含まれるかどうか
      #   whether the canonical text includes indented lines
      def indented?
        @original_text.lines.any? { |line| line.start_with?('  ') }
      end

      # 元の字下げ段数から整形する。行中の空白と出典は保持する。
      # Reformat from the original levels, preserving interior spaces and sources.
      # @param unit [String] 1段分の半角スペースまたはタブ。空文字列は不可
      #   nonempty sequence of ASCII spaces and/or tabs per level
      # @return [Poem] 新しい凍結済みの詩。再抽選や元の値の変更は行わない
      #   new frozen poem; no sampling and no mutation
      # @raise [ArgumentError] 字下げが半角スペースやタブ以外を含む場合、または空の場合
      #   unless unit consists of spaces or tabs
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

    # 短歌一首の全文。
    # One complete tanka.
    class Tanka < Quote
      # @api private
      def self.kind
        :tanka
      end
    end

    # 俳句一句の全文。
    # One complete haiku.
    class Haiku < Quote
      # @api private
      def self.kind
        :haiku
      end
    end

    # 散文から選んだ抜粋。
    # A selected prose excerpt.
    class Passage < Quote
      # @api private
      def self.kind
        :passage
      end
    end
  end

  # 動植物・物・超自然的存在を含む作品の登場者。
  # A story's participant, including animals, objects, and supernatural beings.
  class Being < WarnedValue
    extend NamedLookup

    # @api private
    def self.category
      :beings
    end

    # @return [Being] 凍結された名前
    #   frozen name
    def name
      self
    end

    # @return [Symbol] 辞書で指定した登場者の分類
    #   dictionary-defined classification
    def kind
      self.class.kind
    end
  end

  # 人間または基本的に人間の姿をした登場者。
  # A human or basically human-shaped participant.
  class Person < Being
    # @api private
    def self.kind
      :person
    end
  end

  # 人間以外の動植物や物をもとにした登場者。
  # A participant based on a nonhuman animal, plant, or object.
  class Character < Being
    # @api private
    def self.kind
      :character
    end
  end

  # 超自然的・異形・正体不明の存在。
  # A supernatural, unusual, or unidentified being.
  class Creature < Being
    # @api private
    def self.kind
      :creature
    end
  end

  # 単独で取得する擬音語・擬態語。
  # A standalone onomatopoeic or mimetic phrase.
  class Onomatopoeia < WarnedValue
    # @api private
    def self.category
      :onomatopoeias
    end

    # @return [Onomatopoeia] 凍結された文字列
    #   frozen text
    def text
      self
    end
  end
end
