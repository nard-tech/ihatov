# frozen_string_literal: true

RSpec.describe 'Bundled dictionary' do
  it 'loads all bundled data and exposes the selected editions' do
    expect(Ihatov::Quote.all.size).to eq(35)
    expect(Ihatov::Place.all.size).to eq(7)
    expect(Ihatov::Being.all.size).to eq(14)
    expect(Ihatov::Onomatopoeia.all.size).to eq(9)
    expect(Ihatov::Tono.work.edition.aozora_id).to eq(52_504)
    expect(Ihatov::Kenji::Work.find('銀河鉄道の夜').author.name).to eq('宮沢 賢治')
    expect(Ihatov::Work.all).to all(be_frozen)
  end

  it 'keeps the wind phrase separate from the longer prose excerpt' do
    phrase = Ihatov::Kenji::Onomatopoeia.where(work: '風の又三郎').first
    expect(phrase).to eq('どっどど どどうど どどうど どどう')
    expect(Ihatov::Kenji.quote(work: '風の又三郎')).to include(phrase, '谷川の岸に小さな学校がありました。')
    expect(Ihatov::Kenji.quote(work: '風の又三郎')).not_to eq(phrase)
  end

  it 'supports indented poetry and per-relation provenance in real data' do
    poem = Ihatov::Quote::Poem.where(indent: "\t").find { |item| item.id == 'haru-to-shura-sky' }
    expect(poem).to include("\t\t聖玻璃（せいはり）の風が行き交ひ")
    originals = Ihatov::Quote::Poem.where(indent: true)
    expect(originals.size).to be > 1
    expect(poem.with_indent('  ')).to eq(originals.find { |item| item.id == poem.id })
    expect(Ihatov.poem(indent: "\t")).to satisfy { |item| originals.map(&:id).include?(item.id) }
    place = Ihatov::Kenji::Place.find('イーハトーヴ')
    expect(place.works.map(&:id)).to eq(%w[haru-to-shura gusukobudori-no-denki])
    expect(place.sources.map(&:location)).to eq(['イーハトヴの氷霧', '一 森'])
    expect(Ihatov::Kenji::Place.find('カルボナード火山').work.title).to eq('グスコーブドリの伝記')
  end

  it 'keeps editorial warnings local to the selected item' do
    all_tanka = Ihatov::Takuboku::Quote::Tanka.all
    filtered = Ihatov::Takuboku::Quote::Tanka.where(exclude_content_warnings: true)
    expect(all_tanka.size).to eq(16)
    expect(filtered.size).to eq(15)
    expect(filtered).to all(have_attributes(content_warnings: []))
    expect(Ihatov::Quote.all).to all(satisfy { |text| !text.end_with?("\n") })
  end

  it 'connects the new stories, participants, and sounds to their verified editions' do
    expect(Ihatov::Kenji::Creature.find('クラムボン').work.edition.aozora_id).to eq(46_605)
    expect(Ihatov::Kenji::Character.find('紺三郎').work.edition.aozora_id).to eq(45_679)
    expect(Ihatov::Kenji::Onomatopoeia.where(work: 'やまなし')).to contain_exactly('かぷかぷ', 'トブン')
    opening = Ihatov::Kenji::Quote::Passage.where(work: 'やまなし').find { |item| item.id == 'yamanashi-may' }
    expect(opening).to include('かぷかぷ', 'そのなめらかな天井（てんじょう）を')
    expect(Ihatov::Tono::Creature.find('猿の経立').location).to eq('第46話')
    expect(Ihatov::Takuboku::Place.find('不来方城').real).to be(true)
    expect(Ihatov::Work.all.first.title).to eq('一握の砂')
    expect(Ihatov::Kenji::Work.all.first.title).to eq('雪渡り')
  end

  it 'reports categories awaiting source selection as empty, not fabricated content' do
    expect(Ihatov::Quote::Haiku.all).to eq([])
    expect { Ihatov.haiku }.to raise_error(Ihatov::NotFoundError)
    expect(Ihatov::Place.where(real: true)).to all(have_attributes(coordinates: nil))
  end
end
