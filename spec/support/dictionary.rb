# frozen_string_literal: true

module Ihatov
  # テスト専用の架空データ。文学作品の抜粋としては配布しない。
  # Synthetic fixtures, never distributed as literary quotations.
  module DictionaryFixture
    def edition
      { 'aozora_id' => 1, 'url' => 'https://example.com/card1.html', 'bibliography' => 'Test edition' }
    end

    def documents
      {
        'authors' => [
          { 'id' => 'miyazawa-kenji', 'family_name' => '宮沢', 'given_name' => '賢治' },
          { 'id' => 'ishikawa-takuboku', 'family_name' => '石川', 'given_name' => '啄木' },
          { 'id' => 'yanagita-kunio', 'family_name' => '柳田', 'given_name' => '國男' }
        ],
        'works' => {
          'miyazawa-kenji' => [
            {
              'id' => 'late', 'title' => '後の作品', 'published_year' => 1930, 'edition' => edition,
              'quotes' => [
                { 'id' => 'poem', 'kind' => 'poem', 'text' => "朝\n  光\n    星\n\n  空" },
                { 'id' => 'plain', 'kind' => 'poem', 'text' => "一行目\n二行目" },
                { 'id' => 'warning', 'kind' => 'passage', 'text' => '注意付きのテスト本文',
                  'content_warnings' => ['説明文'] }
              ],
              'places' => [{ 'id' => 'shared', 'name' => '共有地', 'real' => true,
                             'coordinates' => { 'latitude' => 39.7, 'longitude' => 141.1 },
                             'location' => '後の章' }],
              'beings' => [{ 'id' => 'person', 'kind' => 'person', 'name' => '人' }],
              'onomatopoeias' => [{ 'id' => 'sound', 'text' => 'ぽん ぽん' }]
            },
            {
              'id' => 'early', 'title' => '先の作品', 'announced_year' => 1920, 'published_year' => 1940,
              'edition' => edition,
              'places' => [{ 'ref' => 'shared', 'location' => '先の章',
                             'source_url' => 'https://example.com/early.html#chapter' }],
              'quotes' => [{ 'id' => 'haiku', 'kind' => 'haiku', 'text' => 'テスト用の一句' }],
              'beings' => [{ 'id' => 'character', 'kind' => 'character', 'name' => '石' },
                           { 'id' => 'creature', 'kind' => 'creature', 'name' => '怪異' }]
            },
            { 'id' => 'same-year', 'title' => '同年の作品', 'announced_year' => 1920, 'edition' => edition },
            { 'id' => 'unknown', 'title' => '年代不明', 'edition' => edition }
          ],
          'ishikawa-takuboku' => [
            { 'id' => 'tanka-work', 'title' => '歌集', 'published_year' => 1910, 'edition' => edition,
              'quotes' => [{ 'id' => 'tanka', 'kind' => 'tanka', 'text' => "テスト\n短歌\n全体" }],
              'places' => [{ 'ref' => 'shared' }] }
          ],
          'yanagita-kunio' => [
            { 'id' => 'tono-monogatari', 'title' => '遠野物語', 'edition' => edition,
              'quotes' => [{ 'id' => 'tono', 'kind' => 'passage', 'text' => 'テスト用の説話' }] }
          ]
        }
      }
    end

    def load_dictionary(data = documents)
      Dir.mktmpdir('ihatov-spec') do |dir|
        File.write(File.join(dir, 'authors.yml'), { 'authors' => data.fetch('authors') }.to_yaml)
        Dir.mkdir(File.join(dir, 'works'))
        data.fetch('works').each do |author_id, works|
          File.write(File.join(dir, 'works', "#{author_id}.yml"), { 'works' => works }.to_yaml)
        end
        Ihatov::Repository.load(dir)
      end
    end
  end
end
