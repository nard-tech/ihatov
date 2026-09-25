# frozen_string_literal: true

require_relative 'support/dictionary'

RSpec.describe '辞書の検証 Dictionary validation' do
  include Ihatov::DictionaryFixture

  let(:data) { documents }
  let(:repository) { load_dictionary(data) }
  let(:kenji_works) { data['works']['miyazawa-kenji'] }
  let(:quote) { kenji_works[0]['quotes'][0] }
  let(:place) { kenji_works[0]['places'][0] }

  context '作者をまたぐ前方参照があるとき when references cross authors and point forward' do
    let(:places) { repository.items(:places) }

    it '同一項目に出典をまとめること merges sources without duplicating entries' do
      expect(places.size).to eq(1)
      expect(places.first.sources.size).to eq(3)
    end
  end

  context '任意の属性が省略されているとき when optional fields are absent' do
    let(:unknown_work) { repository.items(:works).find { |work| work.id == 'unknown' } }

    before { place.delete('coordinates') }

    it '座標と年代をnilとして読み込むこと loads absent coordinates and years as nil' do
      expect(repository.items(:places).first.coordinates).to be_nil
      expect(unknown_work.announced_year).to be_nil
      expect(unknown_work.published_year).to be_nil
    end
  end

  context '種別が異なる項目でIDが一致するとき when IDs match across categories' do
    before { kenji_works[1]['quotes'][0]['id'] = 'shared' }

    it '種別間の同一IDを許可すること permits matching IDs across categories' do
      expect { repository }.not_to raise_error
    end
  end

  describe '辞書フィールドの検証 dictionary field validation' do
    context '文章形式が異なってもIDが重複するとき when quote IDs repeat across forms' do
      before { kenji_works[1]['quotes'][0]['id'] = 'poem' }

      it 'DataErrorを返すこと raises DataError' do
        expect { repository }.to raise_error(Ihatov::DataError, /duplicate/)
      end
    end

    context '参照先が存在しないとき when a reference is unresolved' do
      before { data['works']['ishikawa-takuboku'][0]['places'][0]['ref'] = 'missing' }

      it 'DataErrorを返すこと raises DataError' do
        expect { repository }.to raise_error(Ihatov::DataError, /reference/)
      end
    end

    context '座標があってもrealがないとき when real is absent despite coordinates' do
      before { place.delete('real') }

      it 'DataErrorを返すこと raises DataError' do
        expect { repository }.to raise_error(Ihatov::DataError, /real/)
      end
    end

    context '架空地名に座標があるとき when a fictional place has coordinates' do
      before { place['real'] = false }

      it 'DataErrorを返すこと raises DataError' do
        expect { repository }.to raise_error(Ihatov::DataError, /coordinates/)
      end
    end

    context '緯度が範囲外のとき when latitude is out of range' do
      before { place['coordinates']['latitude'] = 91 }

      it 'DataErrorを返すこと raises DataError' do
        expect { repository }.to raise_error(Ihatov::DataError, /latitude/)
      end
    end

    context '採用版のURLがないとき when an edition URL is absent' do
      before { kenji_works[0]['edition'].delete('url') }

      it 'DataErrorを返すこと raises DataError' do
        expect { repository }.to raise_error(Ihatov::DataError, /url/)
      end
    end

    context '文章形式が不明なとき when a literary form is unknown' do
      before { quote['kind'] = 'typo' }

      it 'DataErrorを返すこと raises DataError' do
        expect { repository }.to raise_error(Ihatov::DataError, /kind/)
      end
    end

    context '詩の字下げが奇数のとき when poem indentation is odd' do
      before { quote['text'] = "朝\n 星" }

      it 'DataErrorを返すこと raises DataError' do
        expect { repository }.to raise_error(Ihatov::DataError, /indent/)
      end
    end

    context '本文に末尾改行があるとき when text has a trailing newline' do
      before { quote['text'] = "朝\n" }

      it 'DataErrorを返すこと raises DataError' do
        expect { repository }.to raise_error(Ihatov::DataError, /newline/)
      end
    end

    context '属性名に誤記があるとき when an attribute name is misspelled' do
      before { quote['locaton'] = 'typo' }

      it 'DataErrorを返すこと raises DataError' do
        expect { repository }.to raise_error(Ihatov::DataError, /unknown/)
      end
    end

    context 'IDの形式が不正なとき when an ID is malformed' do
      before { kenji_works[0]['id'] = '../escape' }

      it 'DataErrorを返すこと raises DataError' do
        expect { repository }.to raise_error(Ihatov::DataError, /id/)
      end
    end

    context 'URLのスキームが不正なとき when a URL scheme is invalid' do
      before { kenji_works[0]['edition']['url'] = 'javascript:alert(1)' }

      it 'DataErrorを返すこと raises DataError' do
        expect { repository }.to raise_error(Ihatov::DataError, /URL/)
      end
    end

    context '参照項目で属性を上書きするとき when a reference overrides metadata' do
      before { data['works']['ishikawa-takuboku'][0]['places'][0]['real'] = false }

      it 'DataErrorを返すこと raises DataError' do
        expect { repository }.to raise_error(Ihatov::DataError, /unknown/)
      end
    end

    context '収録配列にnilを指定するとき when a collection is nil' do
      before { kenji_works[0]['quotes'] = nil }

      it 'DataErrorを返すこと raises DataError' do
        expect { repository }.to raise_error(Ihatov::DataError, /array/)
      end
    end

    context '作者をまたいで作品IDが重複するとき when work IDs repeat across authors' do
      before { data['works']['yanagita-kunio'][0]['id'] = 'late' }

      it 'DataErrorを返すこと raises DataError' do
        expect { repository }.to raise_error(Ihatov::DataError, /duplicate work/)
      end
    end

    context '分類をまたいで登場者IDが重複するとき when being IDs repeat across kinds' do
      before { kenji_works[1]['beings'][0]['id'] = 'person' }

      it 'DataErrorを返すこと raises DataError' do
        expect { repository }.to raise_error(Ihatov::DataError, /duplicate beings/)
      end
    end

    context '擬音語に全角空白があるとき when onomatopoeia contains fullwidth spaces' do
      before { kenji_works[0]['onomatopoeias'][0]['text'] = 'ぽん　ぽん' }

      it 'DataErrorを返すこと raises DataError' do
        expect { repository }.to raise_error(Ihatov::DataError, /ASCII/)
      end
    end

    context '詩の原本にタブがあるとき when canonical poem text contains tabs' do
      before { quote['text'] = "\t朝" }

      it 'DataErrorを返すこと raises DataError' do
        expect { repository }.to raise_error(Ihatov::DataError, /indent/)
      end
    end
  end

  describe 'YAMLの安全な読み込み safe YAML loading' do
    let(:directory) { Dir.mktmpdir('ihatov-invalid') }
    let(:path) { File.join(directory, 'authors.yml') }

    before { File.write(path, yaml_text) }
    after { FileUtils.remove_entry(directory) }

    context 'キーが重複するとき when keys are duplicated' do
      let(:yaml_text) { "authors: []\nauthors: []\n" }

      it 'DataErrorを返すこと raises DataError' do
        expect { Ihatov::Repository.load(directory) }.to raise_error(Ihatov::DataError, /duplicate/)
      end
    end

    context 'エイリアスがあるとき when aliases are present' do
      let(:yaml_text) { "authors: &authors []\nother: *authors\n" }

      it 'DataErrorを返すこと raises DataError' do
        expect { Ihatov::Repository.load(directory) }.to raise_error(Ihatov::DataError)
      end
    end

    context 'オブジェクトタグがあるとき when object tags are present' do
      let(:yaml_text) { "authors: !ruby/object:Object {}\n" }

      it 'DataErrorを返すこと raises DataError' do
        expect { Ihatov::Repository.load(directory) }.to raise_error(Ihatov::DataError)
      end
    end
  end
end
