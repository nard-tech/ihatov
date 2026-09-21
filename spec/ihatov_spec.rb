# frozen_string_literal: true

require_relative 'support/dictionary'

RSpec.describe Ihatov do
  include Ihatov::DictionaryFixture

  let(:repository) { load_dictionary }

  before { allow(Ihatov).to receive(:repository).and_return(repository) }

  it 'returns frozen String subclasses with natural accessors and source metadata' do
    place = Ihatov::Kenji::Place.find('共有地')
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

  it 'sorts by announced year, then publication year, then definition order, with unknown last' do
    expect(Ihatov::Kenji::Work.all.map(&:id)).to eq(%w[early same-year late unknown])
  end

  it 'does exact matching and returns empty frozen arrays for unmatched searches' do
    expect(Ihatov::Kenji::Work.find('先の作品').title).to eq('先の作品')
    expect { Ihatov::Kenji::Work.find('先の') }.to raise_error(Ihatov::NotFoundError)
    expect(Ihatov::Kenji::Work.where(author: '石川 啄木')).to eq([])
    expect(Ihatov::Kenji::Work.where(author: '石川 啄木')).to be_frozen
    expect(Ihatov::Quote).not_to respond_to(:find)
    expect(Ihatov).not_to respond_to(:entry)
  end

  it 'does not broaden author scopes and handles each literary form' do
    expect(Ihatov::Takuboku.tanka).to be_a(Ihatov::Quote::Tanka)
    expect(Ihatov::Kenji::Quote.haiku).to be_a(Ihatov::Quote::Haiku)
    expect(Ihatov::Kenji::Quote::Haiku.sample).to eq('テスト用の一句')
    expect(Ihatov::Tono.quote).to eq('テスト用の説話')
    expect { Ihatov::Takuboku.poem }.to raise_error(Ihatov::NotFoundError)
    expect { Ihatov::Kenji.quote(author: '石川 啄木') }.to raise_error(Ihatov::NotFoundError)
    expect(Ihatov::Place.where(author: Ihatov::Takuboku.work.author).size).to eq(1)
    expect(Ihatov::Quote.where(work: Ihatov::Kenji::Work.find('先の作品')).map(&:id)).to eq(['haiku'])
  end

  it 'keeps onomatopoeias outside quotes and uses Being subclasses' do
    expect(Ihatov::Kenji.onomatopoeia).to eq('ぽん ぽん')
    expect(Ihatov::Kenji::Onomatopoeia.sample).to be_frozen
    expect(Ihatov::Quote.all.map(&:id)).not_to include('sound')
    expect(Ihatov::Kenji.person).to be_a(Ihatov::Person)
    expect(Ihatov::Kenji.character).to be_a(Ihatov::Character)
    expect(Ihatov::Kenji.creature).to be_a(Ihatov::Creature)
    expect(Ihatov::Being.all).to all(be_a(Ihatov::Being))
  end

  it 'filters before sampling and preserves indentation levels, interior spaces, and sources' do
    original = Ihatov.poem(indent: true)
    expect(original).to eq("朝\n  光\n    星\n\n  空")
    formatted = original.with_indent("\t")
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

  it 'includes warnings by default and excludes only warned entries when requested' do
    expect(Ihatov::Quote.all.map(&:id)).to include('warning')
    safe = Ihatov::Quote.where(exclude_content_warnings: true)
    expect(safe.map(&:id)).not_to include('warning')
    expect(safe).to all(have_attributes(content_warnings: []))
    warning = Ihatov::Quote.all.find { |quote| quote.id == 'warning' }
    expect(warning.content_warnings).to be_frozen
    expect(warning.content_warnings.first).to be_frozen
  end

  it 'validates arguments instead of silently treating them as missing' do
    expect { Ihatov.poem(indent: 2) }.to raise_error(ArgumentError)
    expect { Ihatov.poem(indent: '') }.to raise_error(ArgumentError)
    expect { Ihatov.poem(indent: 'x') }.to raise_error(ArgumentError)
    expect { Ihatov::Place.where(real: nil) }.to raise_error(ArgumentError)
    expect { Ihatov.quote(exclude_content_warnings: nil) }.to raise_error(ArgumentError)
    expect { Ihatov.quote(random: nil) }.to raise_error(ArgumentError)
    expect { Ihatov.quote(author: 1) }.to raise_error(ArgumentError)
    expect { Ihatov.quote(typo: true) }.to raise_error(ArgumentError)
    expect { Ihatov::Work.find(nil) }.to raise_error(ArgumentError)
    expect { Ihatov.seed = '123' }.to raise_error(ArgumentError)
  end

  it 'reproduces the shared random sequence across namespaces' do
    first = Array.new(12) { [Ihatov.quote.id, Ihatov::Kenji.work.id] }
    Ihatov.seed = 1234
    expect(Array.new(12) { [Ihatov.quote.id, Ihatov::Kenji.work.id] }).to eq(first)
  end

  it 'uses caller-owned random generators without consuming the shared generator' do
    expected = Ihatov.quote.id
    Ihatov.seed = 1234
    5.times { Ihatov.quote(random: Random.new(1)) }
    expect(Ihatov.quote.id).to eq(expected)
  end

  it 'samples the combined entry array without author weighting' do
    rng = Random.new(7)
    expected_rng = Random.new(7)
    candidates = Ihatov::Quote.all
    20.times do
      expect(Ihatov.quote(random: rng)).to equal(candidates.sample(random: expected_rng))
    end
  end

  it 'does not consume randomness when formatting' do
    expected = Ihatov.quote
    Ihatov.seed = 1234
    Ihatov::Quote::Poem.where(indent: true).first.with_indent("\t")
    expect(Ihatov.quote).to equal(expected)
  end

  it 'applies scopes and explicit filters to the same source relation' do
    expect(Ihatov::Kenji::Place.where(work: '歌集')).to eq([])
    expect(Ihatov::Place.where(author: '宮沢 賢治', work: '歌集')).to eq([])
    expect(Ihatov::Place.where(author: '石川 啄木', work: '歌集').map(&:id)).to eq(['shared'])
    expect(Ihatov::Kenji::Place.where(author: '石川 啄木')).to eq([])
  end

  it 'uses a work scope for Tono rather than broadening to all of its author' do
    data = documents
    data['works']['yanagita-kunio'] << {
      'id' => 'another-yanagita-work', 'title' => '別の作品', 'edition' => edition,
      'quotes' => [{ 'id' => 'other-quote', 'kind' => 'passage', 'text' => '対象外' }]
    }
    allow(Ihatov).to receive(:repository).and_return(load_dictionary(data))
    expect(Ihatov::Tono::Work.all.map(&:id)).to eq(['tono-monogatari'])
    expect(Ihatov::Tono::Quote.all.map(&:id)).to eq(['tono'])
    expect(Ihatov::Tono::Quote.where(work: '別の作品')).to eq([])
  end

  it 'preserves interior spaces, empty lines, and indentation on the first line' do
    data = documents
    data['works']['miyazawa-kenji'][0]['quotes'][0]['text'] = "  朝 の 空\n\n    光  星"
    allow(Ihatov).to receive(:repository).and_return(load_dictionary(data))
    formatted = Ihatov.poem(indent: "\t")
    expect(formatted).to eq("\t朝 の 空\n\n\t\t光  星")
    expect(formatted.with_indent('    ')).to eq("    朝 の 空\n\n        光  星")
    expect { formatted.with_indent(nil) }.to raise_error(ArgumentError)
  end

  it 'keeps all/where and formatting independent of the random sequence' do
    expected = Ihatov.quote
    Ihatov.seed = 1234
    Ihatov::Work.all
    Ihatov::Quote.where(exclude_content_warnings: true)
    Ihatov::Work.find('先の作品')
    expect(Ihatov.quote).to equal(expected)
  end

  it 'returns empty arrays but raises on sampling after warning exclusion' do
    data = documents
    data['works']['yanagita-kunio'][0]['quotes'][0]['content_warnings'] = ['test warning']
    allow(Ihatov).to receive(:repository).and_return(load_dictionary(data))
    expect(Ihatov::Tono::Quote.where(exclude_content_warnings: true)).to eq([])
    expect { Ihatov::Tono.quote(exclude_content_warnings: true) }.to raise_error(Ihatov::NotFoundError)
    expect(Ihatov::Tono.quote).to eq('テスト用の説話')
  end

  it 'keeps separate identities even when different works have the same title' do
    data = documents
    data['works']['miyazawa-kenji'][1]['title'] = '後の作品'
    allow(Ihatov).to receive(:repository).and_return(load_dictionary(data))
    expect(Ihatov::Place.all.first.works.map(&:id)).to eq(%w[tanka-work early late])
    work = Ihatov::Work.all.find { |item| item.id == 'late' }
    expect(Ihatov::Quote.where(work: work).map(&:id)).to eq(%w[poem plain warning])
  end

  it 'freezes metadata all the way down to author names and source strings' do
    work = Ihatov::Kenji.work
    expect(work.author).to be_frozen
    expect(work.author.family_name).to be_frozen
    expect(work.edition.url).to be_frozen
    expect(work.id).to be_frozen
    expect { Ihatov::Place.all.first.sources[1].location.replace('changed') }.to raise_error(FrozenError)
    expect { Ihatov::Place.all.first.coordinates[:latitude] = 0 }.to raise_error(FrozenError)
    expect { Ihatov::Place.all.first.works.clear }.to raise_error(FrozenError)
  end
end
