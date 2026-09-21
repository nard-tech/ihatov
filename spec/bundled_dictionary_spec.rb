# frozen_string_literal: true

RSpec.describe '同梱辞書 Bundled dictionary' do
  context '同梱辞書を読み込む場合 when loading the bundled dictionary' do
    it '収録件数と採用版が一致すること exposes expected counts and editions' do
      expect(Ihatov::Quote.all.size).to eq(36)
      expect(Ihatov::Place.all.size).to eq(7)
      expect(Ihatov::Being.all.size).to eq(15)
      expect(Ihatov::Onomatopoeia.all.size).to eq(9)
      expect(Ihatov::Tono.work.edition.aozora_id).to eq(52_504)
      expect(Ihatov::Kenji::Work.find('銀河鉄道の夜').author.name).to eq('宮沢 賢治')
      expect(Ihatov::Work.all).to all(be_frozen)
    end
  end

  context '風の又三郎の擬音語と抜粋を取得する場合 when selecting the wind phrase and passage' do
    let(:phrase) { Ihatov::Kenji::Onomatopoeia.where(work: '風の又三郎').first }
    let(:passages) { Ihatov::Kenji::Quote::Passage.where(work: '風の又三郎') }
    let(:song) { passages.find { |item| item.id == 'kaze-no-matasaburo-opening' } }
    let(:school) { passages.find { |item| item.id == 'kaze-no-matasaburo-school' } }

    it '擬音語と歌全体の抜粋を区別すること distinguishes the phrase from the complete song' do
      expect(phrase).to eq('どっどど どどうど どどうど どどう')
      expect(song.lines(chomp: true)).to eq([phrase, '青いくるみも吹きとばせ', 'すっぱいかりんも吹きとばせ', phrase])
    end

    it '歌と学校の描写を別の抜粋として返すこと returns the song and school description as separate passages' do
      expect(passages.map(&:id)).to eq(%w[kaze-no-matasaburo-opening kaze-no-matasaburo-school])
      expect(school).to start_with("谷川の岸に小さな学校がありました。\n教室はたった一つでしたが")
      expect(school).to end_with('岩穴もあったのです。')
      expect(school).not_to include(phrase)
      expect(passages).to all(have_attributes(work: Ihatov::Kenji::Work.find('風の又三郎')))
      expect(passages.map(&:source_url).uniq).to eq(['https://www.aozora.gr.jp/cards/000081/files/462_15405.html'])
    end
  end

  context '散文を一覧取得する場合 when listing passages' do
    let(:lines) { Ihatov::Quote::Passage.all.flat_map(&:lines) }

    it '段落頭に字下げを含めないこと omits paragraph indentation' do
      expect(lines).to all(satisfy { |line| !line.match?(/\A[ \t　]/) })
    end
  end

  context '字下げのある詩を取得する場合 when selecting indented poems' do
    let(:poem) { Ihatov::Quote::Poem.where(indent: "\t").find { |item| item.id == 'haru-to-shura-sky' } }
    let(:originals) { Ihatov::Quote::Poem.where(indent: true) }

    it '字下げを保持して整形できること preserves indentation when formatting' do
      expect(poem).to include("\t\t聖玻璃（せいはり）の風が行き交ひ")
      expect(originals.size).to be > 1
      expect(poem.with_indent('  ')).to eq(originals.find { |item| item.id == poem.id })
      expect(originals.map(&:id)).to include(Ihatov.poem(indent: "\t").id)
    end
  end

  context '共有地名を取得する場合 when selecting shared places' do
    let(:place) { Ihatov::Kenji::Place.find('イーハトーヴ') }

    it '作品ごとの出典を保持すること preserves per-work sources' do
      expect(place.works.map(&:id)).to eq(%w[haru-to-shura gusukobudori-no-denki])
      expect(place.sources.map(&:location)).to eq(['イーハトヴの氷霧', '一 森'])
      expect(Ihatov::Kenji::Place.find('カルボナード火山島').work.title).to eq('グスコーブドリの伝記')
    end
  end

  context '短歌の注意情報を除外する場合 when filtering tanka warnings' do
    let(:all_tanka) { Ihatov::Takuboku::Quote::Tanka.all }
    let(:filtered) { Ihatov::Takuboku::Quote::Tanka.where(exclude_content_warnings: true) }

    it '注意のある項目だけを除外すること excludes only warned entries' do
      expect(all_tanka.size).to eq(16)
      expect(filtered.size).to eq(15)
      expect(filtered).to all(have_attributes(content_warnings: []))
      expect(Ihatov::Quote.all).to all(satisfy { |text| !text.end_with?("\n") })
    end
  end

  context 'やまなしの項目を取得する場合 when selecting Yamanashi entries' do
    let(:opening) { Ihatov::Kenji::Quote::Passage.where(work: 'やまなし').find { |item| item.id == 'yamanashi-may' } }

    it '各項目が確認済みの出典に結び付くこと connects entries to verified sources' do
      expect(Ihatov::Kenji::Creature.find('クラムボン').work.edition.aozora_id).to eq(46_605)
      expect(Ihatov::Kenji::Onomatopoeia.where(work: 'やまなし')).to contain_exactly('かぷかぷ', 'トブン')
      expect(opening).to include('かぷかぷ', 'そのなめらかな天井（てんじょう）を')
    end
  end

  context '雪渡りの登場者を取得する場合 when selecting a Yukiwatari character' do
    let(:character) { Ihatov::Kenji::Character.find('紺三郎') }

    it '確認済みの採用版に結び付くこと links to the verified edition' do
      expect(character.work.edition.aozora_id).to eq(45_679)
    end
  end

  context '遠野物語の登場者を取得する場合 when selecting Tono Monogatari beings' do
    let(:oshirasama) { Ihatov::Tono::Creature.find('オシラサマ') }

    it '採用版と話数に結び付くこと links to the edition and tale number' do
      expect(Ihatov::Tono::Creature.find('猿の経立').location).to eq('第46話')
      expect(oshirasama).to have_attributes(id: 'oshirasama', location: '第69話')
      expect(oshirasama.work.edition.aozora_id).to eq(52_504)
    end
  end

  context '実在地名を取得する場合 when selecting real places' do
    let(:places) { Ihatov::Place.where(real: true) }

    it '実在性と座標の未登録を区別すること distinguishes real places from available coordinates' do
      expect(Ihatov::Takuboku::Place.find('不来方城').real).to be(true)
      expect(places).to all(have_attributes(coordinates: nil))
    end
  end

  context '同梱作品を一覧取得する場合 when listing bundled works' do
    it '発表年または刊行年で並ぶこと orders works by announcement or publication year' do
      expect(Ihatov::Work.all.first.title).to eq('一握の砂')
      expect(Ihatov::Kenji::Work.all.first.title).to eq('雪渡り')
    end
  end

  context '未収録の俳句を取得する場合 when requesting unregistered haiku' do
    it '本文を捏造せず未収録として扱うこと reports missing data without fabricated content' do
      expect(Ihatov::Quote::Haiku.all).to eq([])
      expect { Ihatov.haiku }.to raise_error(Ihatov::NotFoundError)
    end
  end
end
