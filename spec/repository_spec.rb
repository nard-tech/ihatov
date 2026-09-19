# frozen_string_literal: true

require_relative 'support/dictionary'

RSpec.describe 'Dictionary validation' do
  include DictionaryFixture

  it 'rejects duplicate IDs across kinds, but permits IDs in different categories' do
    data = documents
    data['works']['miyazawa-kenji'][1]['quotes'][0]['id'] = 'poem'
    expect { load_dictionary(data) }.to raise_error(Ihatov::DataError, /duplicate/)
    data['works']['miyazawa-kenji'][1]['quotes'][0]['id'] = 'shared'
    expect { load_dictionary(data) }.not_to raise_error
  end

  it 'resolves forward and cross-author references without duplicating entities' do
    repository = load_dictionary
    expect(repository.items(:places).size).to eq(1)
    expect(repository.items(:places).first.sources.size).to eq(3)
  end

  it 'rejects dangling references' do
    data = documents
    data['works']['ishikawa-takuboku'][0]['places'][0]['ref'] = 'missing'
    expect { load_dictionary(data) }.to raise_error(Ihatov::DataError, /reference/)
  end

  it 'requires real independently of coordinates' do
    data = documents
    data['works']['miyazawa-kenji'][0]['places'][0].delete('real')
    expect { load_dictionary(data) }.to raise_error(Ihatov::DataError, /real/)
  end

  it 'rejects coordinates on fictional places and out-of-range real coordinates' do
    data = documents
    place = data['works']['miyazawa-kenji'][0]['places'][0]
    place['real'] = false
    expect { load_dictionary(data) }.to raise_error(Ihatov::DataError, /coordinates/)
    place['real'] = true
    place['coordinates']['latitude'] = 91
    expect { load_dictionary(data) }.to raise_error(Ihatov::DataError, /latitude/)
  end

  it 'allows absent arrays, years, locations, warnings and coordinates' do
    data = documents
    data['works']['miyazawa-kenji'][0]['places'][0].delete('coordinates')
    repository = load_dictionary(data)
    expect(repository.items(:places).first.coordinates).to be_nil
    unknown = repository.items(:works).find { |work| work.id == 'unknown' }
    expect(unknown.announced_year).to be_nil
    expect(unknown.published_year).to be_nil
  end

  it 'requires complete editions and rejects unknown kinds' do
    data = documents
    data['works']['miyazawa-kenji'][0]['edition'].delete('url')
    expect { load_dictionary(data) }.to raise_error(Ihatov::DataError, /url/)
    data = documents
    data['works']['miyazawa-kenji'][0]['quotes'][0]['kind'] = 'typo'
    expect { load_dictionary(data) }.to raise_error(Ihatov::DataError, /kind/)
  end

  it 'rejects YAML duplicate keys instead of silently overwriting entries' do
    Dir.mktmpdir('ihatov-invalid') do |dir|
      File.write(File.join(dir, 'authors.yml'), "authors: []\nauthors: []\n")
      expect { Ihatov::Repository.load(dir) }.to raise_error(Ihatov::DataError, /duplicate/)
    end
  end

  it 'rejects odd poem indentation, trailing newlines, and unknown keys' do
    data = documents
    data['works']['miyazawa-kenji'][0]['quotes'][0]['text'] = "朝\n 星"
    expect { load_dictionary(data) }.to raise_error(Ihatov::DataError, /indent/)
    data['works']['miyazawa-kenji'][0]['quotes'][0]['text'] = "朝\n"
    expect { load_dictionary(data) }.to raise_error(Ihatov::DataError, /newline/)
    data['works']['miyazawa-kenji'][0]['quotes'][0]['text'] = '朝'
    data['works']['miyazawa-kenji'][0]['quotes'][0]['locaton'] = 'typo'
    expect { load_dictionary(data) }.to raise_error(Ihatov::DataError, /unknown/)
  end

  it 'rejects wrong field types, invalid IDs, URLs, and unknown reference overrides' do
    data = documents
    data['works']['miyazawa-kenji'][0]['id'] = '../escape'
    expect { load_dictionary(data) }.to raise_error(Ihatov::DataError, /id/)
    data = documents
    data['works']['miyazawa-kenji'][0]['edition']['url'] = 'javascript:alert(1)'
    expect { load_dictionary(data) }.to raise_error(Ihatov::DataError, /URL/)
    data = documents
    data['works']['ishikawa-takuboku'][0]['places'][0]['real'] = false
    expect { load_dictionary(data) }.to raise_error(Ihatov::DataError, /unknown/)
    data = documents
    data['works']['miyazawa-kenji'][0]['quotes'] = nil
    expect { load_dictionary(data) }.to raise_error(Ihatov::DataError, /array/)
  end

  it 'rejects duplicate work and being IDs globally' do
    data = documents
    data['works']['yanagita-kunio'][0]['id'] = 'late'
    expect { load_dictionary(data) }.to raise_error(Ihatov::DataError, /duplicate work/)
    data = documents
    data['works']['miyazawa-kenji'][1]['beings'][0]['id'] = 'person'
    expect { load_dictionary(data) }.to raise_error(Ihatov::DataError, /duplicate beings/)
  end

  it 'rejects YAML aliases and unsafe object tags' do
    Dir.mktmpdir('ihatov-unsafe') do |dir|
      path = File.join(dir, 'authors.yml')
      File.write(path, "authors: &authors []\nother: *authors\n")
      expect { Ihatov::Repository.load(dir) }.to raise_error(Ihatov::DataError)
      File.write(path, "authors: !ruby/object:Object {}\n")
      expect { Ihatov::Repository.load(dir) }.to raise_error(Ihatov::DataError)
    end
  end

  it 'requires ASCII whitespace in onomatopoeias and canonical indentation in poems' do
    data = documents
    data['works']['miyazawa-kenji'][0]['onomatopoeias'][0]['text'] = 'ぽん　ぽん'
    expect { load_dictionary(data) }.to raise_error(Ihatov::DataError, /ASCII/)
    data = documents
    data['works']['miyazawa-kenji'][0]['quotes'][0]['text'] = "\t朝"
    expect { load_dictionary(data) }.to raise_error(Ihatov::DataError, /indent/)
  end
end
