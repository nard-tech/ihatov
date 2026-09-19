# frozen_string_literal: true

RSpec.describe 'Bundled dictionary' do
  it 'loads all bundled data and exposes the selected editions' do
    expect(Ihatov::Quote.all.size).to eq(10)
    expect(Ihatov::Place.all.size).to eq(4)
    expect(Ihatov::Being.all.size).to eq(8)
    expect(Ihatov::Onomatopoeia.all.size).to eq(4)
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
    poem = Ihatov.poem(indent: "\t")
    expect(poem).to include("\t\t聖玻璃（せいはり）の風が行き交ひ")
    expect(poem.with_indent('  ')).to eq(Ihatov.poem(indent: true))
    place = Ihatov::Kenji::Place.find('イーハトーヴ')
    expect(place.works.map(&:id)).to eq(%w[haru-to-shura gusukobudori-no-denki])
    expect(place.sources.map(&:location)).to eq(['イーハトヴの氷霧', '一 森'])
    expect(Ihatov::Kenji::Place.find('カルボナード火山').work.title).to eq('グスコーブドリの伝記')
  end

  it 'keeps editorial warnings local to the selected item' do
    all_tanka = Ihatov::Takuboku::Quote::Tanka.all
    filtered = Ihatov::Takuboku::Quote::Tanka.where(exclude_content_warnings: true)
    expect(all_tanka.size).to eq(4)
    expect(filtered.size).to eq(3)
    expect(filtered).to all(have_attributes(content_warnings: []))
    expect(Ihatov::Quote.all).to all(satisfy { |text| !text.end_with?("\n") })
  end

  it 'reports categories awaiting source selection as empty, not fabricated content' do
    expect(Ihatov::Quote::Haiku.all).to eq([])
    expect { Ihatov.haiku }.to raise_error(Ihatov::NotFoundError)
    expect(Ihatov::Place.where(real: true)).to all(have_attributes(coordinates: nil))
  end
end
