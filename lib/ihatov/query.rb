# frozen_string_literal: true

module Ihatov
  # 明示的に定義した公開検索クラスで共有するコレクション操作。
  # Collection methods shared by the explicit public query classes.
  module Collection
    # 抽選せずに全項目を年代順で取得する。
    # All entries in chronological order, without sampling.
    # @return [Array<String>] 凍結された値を格納した凍結配列
    #   frozen array of frozen values
    def all
      where
    end

    # 名前空間の範囲内で、すべての条件に一致する項目を取得する。
    # Match conditions with AND, retaining the namespace's scope.
    # @param conditions [Hash] 作者・作品と種別ごとの絞り込み条件
    #   author, work, and category-specific filters
    # @option conditions [Author, String] :author 登録された作者名または作者オブジェクト
    #   registered author name or object
    # @option conditions [Work, String] :work 登録された題名または作品オブジェクト
    #   registered title or object
    # @option conditions [Boolean] :real 地名だけに適用
    #   only for places
    # @option conditions [Boolean, String] :indent 詩のみ。trueは字下げあり、falseは字下げなし。
    #   文字列を指定すると字下げありの詩を選び、その文字列で整形する。
    #   Only for poems; true selects
    #   indented poems, false selects others, a string also formats indentation
    # @option conditions [Boolean] :exclude_content_warnings (false) 注意情報のある項目を除外
    #   omit warned entries
    # @return [Array<String>] 凍結配列。一致する項目がなければ空配列
    #   frozen array; no matches returns an empty array
    # @raise [ArgumentError] 未対応または不正な絞り込み条件の場合
    #   if a filter is unsupported or malformed
    def where(**conditions)
      Query.new(self, conditions).all
    end

    # 条件に合う項目をそれぞれ等しい確率で抽選する。
    # Select uniformly from the matching entries, not from authors.
    # @param random [Random] 乱数生成器。省略時はIhatovで共有するものを使用
    #   generator; defaults to Ihatov's shared generator
    # @param conditions [Hash] {#where}と同じ絞り込み条件
    #   same filters as {#where}
    # @return [String] メタデータを持つ、凍結されたString派生オブジェクト
    #   frozen metadata-bearing String subclass
    # @raise [ArgumentError] 不正な引数の場合
    #   for invalid arguments
    # @raise [NotFoundError] 一致する項目がない場合
    #   when no entries match
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

  # 名前を持つ項目の完全一致検索。抜粋には提供しない。
  # Exact-name lookup for named entities (not quotations).
  module NamedLookup
    # @param name [String] 登録された題名または名前。正規化せず完全一致で検索
    #   exact registered title or name, without normalization
    # @param conditions [Hash] whereと同じ絞り込み条件
    #   same filters as where
    # @return [String] 一致した項目のうち年代順で最初の凍結された値
    #   first matching frozen value in chronological order
    # @raise [ArgumentError] 不正な引数の場合
    #   for invalid arguments
    # @raise [NotFoundError] この範囲に一致する名前が登録されていない場合
    #   if the name is not registered in this scope
    def find(name, **conditions)
      raise ArgumentError, 'name must be a String' unless name.is_a?(String)

      where(**conditions).find { |item| item == name } || raise(NotFoundError, "not found: #{name}")
    end
  end

  # 抽選前に絞り込み、選択された結果だけを整形する。
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
                when :author, :work then value.is_a?(String)
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
        matches_scope?(work) && matches_author?(work.author) && matches_title?(work)
      end
    end

    def matches_scope?(work)
      scope = @collection.scope
      (!scope[:author_id] || work.author.id == scope[:author_id]) &&
        (!scope[:work_id] || work.id == scope[:work_id])
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
