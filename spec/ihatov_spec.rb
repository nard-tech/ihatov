# frozen_string_literal: true

require_relative 'support/dictionary'

RSpec.describe Ihatov do
  include Ihatov::DictionaryFixture

  let(:data) { documents }
  let(:repository) { load_dictionary(data) }

  before { allow(Ihatov).to receive(:repository) { repository } }

  context '共有地名を取得するとき when retrieving a shared place' do
    let(:place) { Ihatov::Kenji::Place.find('共有地') }

    it '凍結した文字列と出典情報を返すこと returns frozen strings with source metadata' do
      expect(place).to be_a(String)
      expect(place.name).to eq('共有地')
      expect(place).to be_frozen
      expect(place.coordinates).to eq(latitude: 39.7, longitude: 141.1)
      expect(place.coordinates).to be_frozen
      expect(place).not_to respond_to(:content_warnings)
      expect(place.works.map(&:id)).to eq(%w[tanka-work early late])
      expect(place.work).to equal(place.works.first)
      expect(place.work.author.name).to eq('石川 啄木')
      expect(place.sources).to be_frozen
      expect(place.sources.first).to be_frozen
      expect(place.works).to be_frozen
      expect(place.source_url).to eq('https://example.com/card1.html')
      expect(place.sources[1].source_url).to end_with('#chapter')
      expect(place.sources[1].location).to eq('先の章')
      expect(place.work.edition.bibliography).to be_frozen
      expect { place.replace('changed') }.to raise_error(FrozenError)
    end
  end

  context '作品を年代順に取得するとき when ordering works' do
    it '発表年・刊行年・定義順で並び年代不明を末尾に置くこと orders works by date and definition order' do
      expect(Ihatov::Kenji::Work.all.map(&:id)).to eq(%w[early same-year late unknown])
    end
  end

  context '名前と作者で検索するとき when searching by name and author' do
    it '完全一致で検索し該当なしでは凍結した空配列を返すこと matches exact names and returns frozen empty arrays' do
      expect(Ihatov::Kenji::Work.find('先の作品').title).to eq('先の作品')
      expect { Ihatov::Kenji::Work.find('先の') }.to raise_error(Ihatov::NotFoundError)
      expect(Ihatov::Kenji::Work.where(author: '石川 啄木')).to eq([])
      expect(Ihatov::Kenji::Work.where(author: '石川 啄木')).to be_frozen
      expect(Ihatov::Quote).not_to respond_to(:find)
      expect(Ihatov).not_to respond_to(:entry)
    end
  end

  context '作者別に文章を取得するとき when selecting literary forms by author' do
    it '作者の範囲を保ち各文章形式を取得できること preserves author scopes and literary forms' do
      expect(Ihatov::Takuboku.tanka).to be_a(Ihatov::Quote::Tanka)
      expect(Ihatov::Kenji::Quote.haiku).to be_a(Ihatov::Quote::Haiku)
      expect(Ihatov::Kenji::Quote::Haiku.sample).to eq('テスト用の一句')
      expect(Ihatov::Tono.quote).to eq('テスト用の説話')
      expect { Ihatov::Takuboku.poem }.to raise_error(Ihatov::NotFoundError)
      expect { Ihatov::Kenji.quote(author: '石川 啄木') }.to raise_error(Ihatov::NotFoundError)
      expect(Ihatov::Place.where(author: Ihatov::Takuboku.work.author).size).to eq(1)
      expect(Ihatov::Quote.where(work: Ihatov::Kenji::Work.find('先の作品')).map(&:id)).to eq(['haiku'])
    end
  end

  context '擬音語と登場者を取得するとき when selecting sounds and beings' do
    it '擬音語を抜粋と区別し登場者を分類して返すこと separates sounds and classifies beings' do
      expect(Ihatov::Kenji.onomatopoeia).to eq('ぽん ぽん')
      expect(Ihatov::Kenji::Onomatopoeia.sample).to be_frozen
      expect(Ihatov::Quote.all.map(&:id)).not_to include('sound')
      expect(Ihatov::Kenji.person).to be_a(Ihatov::Person)
      expect(Ihatov::Kenji.character).to be_a(Ihatov::Character)
      expect(Ihatov::Kenji.creature).to be_a(Ihatov::Creature)
      expect(Ihatov::Being.all).to all(be_a(Ihatov::Being))
    end
  end

  context '字下げのある詩を整形するとき when formatting an indented poem' do
    let(:original) { Ihatov.poem(indent: true) }
    let(:formatted) { original.with_indent("\t") }

    it '抽選前に絞り込み字下げの段数と出典を保持すること filters before sampling and preserves indentation and sources' do
      expect(original).to eq("朝\n  光\n    星\n\n  空")
      expect(formatted).to eq("朝\n\t光\n\t\t星\n\n\t空")
      expect(formatted.with_indent('    ')).to eq("朝\n    光\n        星\n\n    空")
      expect(formatted.sources).to eq(original.sources)
      expect(formatted).to be_frozen
      expect(original).to include('  光')
      expect(Ihatov.poem(indent: false).id).to eq('plain')
      expect(Ihatov.poem(indent: "\t")).to eq(formatted)
      expect(Ihatov::Kenji::Quote::Poem.where(indent: '    ').first).to eq(original.with_indent('    '))
      expect(Ihatov::Quote::Poem.all.size).to eq(2)
    end
  end

  context '注意情報の有無で絞り込むとき when filtering content warnings' do
    let(:safe) { Ihatov::Quote.where(exclude_content_warnings: true) }
    let(:warning) { Ihatov::Quote.all.find { |quote| quote.id == 'warning' } }

    it '通常は注意付き項目を含み指定時だけ除外すること excludes only warned entries when requested' do
      expect(Ihatov::Quote.all.map(&:id)).to include('warning')
      expect(safe.map(&:id)).not_to include('warning')
      expect(safe).to all(have_attributes(content_warnings: []))
      expect(warning.content_warnings).to be_frozen
      expect(warning.content_warnings.first).to be_frozen
    end
  end

  describe '引数の検証 argument validation' do
    context '字下げに数値を指定したとき when indentation is numeric' do
      it 'ArgumentError を返すこと raises ArgumentError' do
        expect { Ihatov.poem(indent: 2) }.to raise_error(ArgumentError)
      end
    end

    context '字下げに空文字列を指定したとき when indentation is empty' do
      it 'ArgumentError を返すこと raises ArgumentError' do
        expect { Ihatov.poem(indent: '') }.to raise_error(ArgumentError)
      end
    end

    context '字下げに通常文字を指定したとき when indentation contains text' do
      it 'ArgumentError を返すこと raises ArgumentError' do
        expect { Ihatov.poem(indent: 'x') }.to raise_error(ArgumentError)
      end
    end

    context 'real に nil を指定したとき when real is nil' do
      it 'ArgumentError を返すこと raises ArgumentError' do
        expect { Ihatov::Place.where(real: nil) }.to raise_error(ArgumentError)
      end
    end

    context '除外条件に nil を指定したとき when the warning filter is nil' do
      it 'ArgumentError を返すこと raises ArgumentError' do
        expect { Ihatov.quote(exclude_content_warnings: nil) }.to raise_error(ArgumentError)
      end
    end

    context '乱数生成器に nil を指定したとき when the generator is nil' do
      it 'ArgumentError を返すこと raises ArgumentError' do
        expect { Ihatov.quote(random: nil) }.to raise_error(ArgumentError)
      end
    end

    context '作者に数値を指定したとき when the author is numeric' do
      it 'ArgumentError を返すこと raises ArgumentError' do
        expect { Ihatov.quote(author: 1) }.to raise_error(ArgumentError)
      end
    end

    context '未対応の条件を指定したとき when the condition is unsupported' do
      it 'ArgumentError を返すこと raises ArgumentError' do
        expect { Ihatov.quote(typo: true) }.to raise_error(ArgumentError)
      end
    end

    context '検索名に nil を指定したとき when the lookup name is nil' do
      it 'ArgumentError を返すこと raises ArgumentError' do
        expect { Ihatov::Work.find(nil) }.to raise_error(ArgumentError)
      end
    end

    context 'seed に文字列を指定したとき when the seed is a string' do
      it 'ArgumentError を返すこと raises ArgumentError' do
        expect { Ihatov.seed = '123' }.to raise_error(ArgumentError)
      end
    end
  end

  context '同じ seed を再設定するとき when resetting the same seed' do
    it '名前空間をまたいで乱数列を再現できること reproduces random sequences across namespaces' do
      first = Array.new(12) { [Ihatov.quote.id, Ihatov::Kenji.work.id] }
      Ihatov.seed = 1234
      expect(Array.new(12) { [Ihatov.quote.id, Ihatov::Kenji.work.id] }).to eq(first)
    end
  end

  context '個別の Random を指定するとき when supplying an independent Random' do
    it '個別の乱数生成器で共有の乱数列を消費しないこと preserves the shared random sequence' do
      expected = Ihatov.quote.id
      Ihatov.seed = 1234
      5.times { Ihatov.quote(random: Random.new(1)) }
      expect(Ihatov.quote.id).to eq(expected)
    end
  end

  context '作者を指定せず抽選するとき when sampling across authors' do
    let(:rng) { Random.new(7) }
    let(:expected_rng) { Random.new(7) }
    let(:candidates) { Ihatov::Quote.all }

    it '作者で重み付けせず項目を均等に抽選すること samples entries uniformly' do
      20.times do
        expect(Ihatov.quote(random: rng)).to equal(candidates.sample(random: expected_rng))
      end
    end
  end

  context '抽選せず字下げを整形するとき when formatting without sampling' do
    it '字下げの整形で乱数を消費しないこと does not consume randomness' do
      expected = Ihatov.quote
      Ihatov.seed = 1234
      Ihatov::Quote::Poem.where(indent: true).first.with_indent("\t")
      expect(Ihatov.quote).to equal(expected)
    end
  end

  context '複数の出典に検索条件を指定するとき when filtering shared source relations' do
    it '名前空間と明示条件を同じ出典関係に適用すること matches conditions on the same source relation' do
      expect(Ihatov::Kenji::Place.where(work: '歌集')).to eq([])
      expect(Ihatov::Place.where(author: '宮沢 賢治', work: '歌集')).to eq([])
      expect(Ihatov::Place.where(author: '石川 啄木', work: '歌集').map(&:id)).to eq(['shared'])
      expect(Ihatov::Kenji::Place.where(author: '石川 啄木')).to eq([])
    end
  end

  context '柳田國男の他作品も存在するとき when another Yanagita work exists' do
    before do
      data['works']['yanagita-kunio'] << {
        'id' => 'another-yanagita-work', 'title' => '別の作品', 'edition' => edition,
        'quotes' => [{ 'id' => 'other-quote', 'kind' => 'passage', 'text' => '対象外' }]
      }
    end

    it '遠野物語だけを対象にして作者の他作品を含めないこと limits results to Tono Monogatari' do
      expect(Ihatov::Tono::Work.all.map(&:id)).to eq(['tono-monogatari'])
      expect(Ihatov::Tono::Quote.all.map(&:id)).to eq(['tono'])
      expect(Ihatov::Tono::Quote.where(work: '別の作品')).to eq([])
    end
  end

  context '先頭行にも字下げがあるとき when the first line is indented' do
    let(:formatted) { Ihatov.poem(indent: "\t") }

    before do
      data['works']['miyazawa-kenji'][0]['quotes'][0]['text'] = "  朝 の 空\n\n    光  星"
    end

    it '先頭行の字下げと行中の空白と空行を保持すること preserves leading indentation and whitespace' do
      expect(formatted).to eq("\t朝 の 空\n\n\t\t光  星")
      expect(formatted.with_indent('    ')).to eq("    朝 の 空\n\n        光  星")
      expect { formatted.with_indent(nil) }.to raise_error(ArgumentError)
    end
  end

  context '抽選の間に一覧取得と検索を行うとき when querying between samples' do
    it '一覧取得と検索で乱数を消費しないこと does not consume randomness' do
      expected = Ihatov.quote
      Ihatov.seed = 1234
      Ihatov::Work.all
      Ihatov::Quote.where(exclude_content_warnings: true)
      Ihatov::Work.find('先の作品')
      expect(Ihatov.quote).to equal(expected)
    end
  end

  context '除外条件で全項目がなくなるとき when every item is excluded' do
    before do
      data['works']['yanagita-kunio'][0]['quotes'][0]['content_warnings'] = ['test warning']
    end

    it '除外後の一覧は空配列を返し抽選は例外になること returns empty lists and raises on sampling' do
      expect(Ihatov::Tono::Quote.where(exclude_content_warnings: true)).to eq([])
      expect { Ihatov::Tono.quote(exclude_content_warnings: true) }.to raise_error(Ihatov::NotFoundError)
      expect(Ihatov::Tono.quote).to eq('テスト用の説話')
    end
  end

  context '異なる作品が同じ題名を持つとき when distinct works share a title' do
    let(:work) { Ihatov::Work.all.find { |item| item.id == 'late' } }

    before do
      data['works']['miyazawa-kenji'][1]['title'] = '後の作品'
    end

    it '同名の別作品でも識別子を区別すること preserves distinct work identities' do
      expect(Ihatov::Place.all.first.works.map(&:id)).to eq(%w[tanka-work early late])
      expect(Ihatov::Quote.where(work: work).map(&:id)).to eq(%w[poem plain warning])
    end
  end

  context '返却値のメタデータを変更するとき when mutating returned metadata' do
    let(:work) { Ihatov::Kenji.work }

    it '作者名や出典文字列を含めメタデータを凍結すること deeply freezes metadata' do
      expect(work.author).to be_frozen
      expect(work.author.family_name).to be_frozen
      expect(work.edition.url).to be_frozen
      expect(work.id).to be_frozen
      expect { Ihatov::Place.all.first.sources[1].location.replace('changed') }.to raise_error(FrozenError)
      expect { Ihatov::Place.all.first.coordinates[:latitude] = 0 }.to raise_error(FrozenError)
      expect { Ihatov::Place.all.first.works.clear }.to raise_error(FrozenError)
    end
  end
end
