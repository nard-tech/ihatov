# frozen_string_literal: true

RSpec.describe Ihatov::Tono do
  let(:work) { Ihatov::Tono::Work.find('遠野物語') }

  describe Ihatov::Tono::Work do
    it '作品と採用版の情報を返すこと returns the work and adopted edition metadata' do
      expect(described_class.all).to eq([work])

      expect(work).to have_attributes(id: 'tono-monogatari', published_year: 1910)
      expect(work.author.name).to eq('柳田 國男')
      expect(work.edition).to have_attributes(
        aozora_id: 52_504,
        url: 'https://www.aozora.gr.jp/cards/001566/card52504.html'
      )
    end
  end

  describe Ihatov::Tono::Place do
    let(:all_places) { described_class.all }

    context '遠野物語に関連する地名を取得するとき when requesting Tono-related places' do
      it '辞書の順で 30 地名の ID と名称を返すこと returns all IDs and names in dictionary order' do
        expect(all_places.map { |place| [place.id, place.name] }).to eq(
          [
            %w[sarugaishi-gawa 猿ヶ石川],
            %w[sennin-toge 仙人峠],
            %w[tono-go 遠野郷],
            %w[hayachine 早池峯],
            %w[rokko-ushi-yama 六角牛山],
            %w[mayoiga マヨイガ],
            %w[denderano デンデラノ],
            %w[danno-hana ダンノハナ],
            %w[rendaino 蓮台野],
            %w[tsuchibuchi 土淵],
            %w[yamaguchi 山口],
            %w[tsukumoushi 附馬牛],
            %w[ayori 綾織],
            %w[aozasa 青笹],
            %w[kamigo 上郷],
            %w[otomo 小友],
            %w[miyamori 宮守],
            %w[tassobe 達曾部],
            %w[fuefuki-toge 笛吹峠],
            %w[sakaigi-toge 境木峠],
            %w[hashino 橋野],
            %w[oguni 小国],
            %w[yamada 山田],
            %w[kamaishi 釜石],
            %w[funakoshi 船越],
            %w[kirikiri 吉利吉里],
            %w[tanohama 田ノ浜],
            %w[ishigami-yama 石神山],
            %w[tsuzukiishi 続石],
            %w[mukeyama 向山]
          ]
        )
      end

      it '実在性と出典を返すこと returns reality and source metadata' do
        expect(all_places.count(&:real)).to eq(29)
        expect(all_places).to all(have_attributes(work: work))

        expect(described_class.find('マヨイガ')).to have_attributes(
          real: false,
          location: '第63話・山中の不思議な家の呼称'
        )
        expect(described_class.find('デンデラノ').source_url).to include('tonojikan.jp')
      end
    end
  end

  describe Ihatov::Tono::Being do
    let(:all_beings) { described_class.all }

    it '辞書の順で 8 登場者の ID・名称・分類を返すこと returns all being attributes in dictionary order' do
      expect(all_beings.map { |being| [being.id, being.name, being.kind] }).to eq(
        [
          ['sasaki-kizen', '佐々木喜善', :person],
          ['konsesama', 'コンセサマ', :creature],
          ['gongesama', 'ゴンゲサマ', :creature],
          ['oshirasama', 'オシラサマ', :creature],
          ['saru-no-futtachi', '猿の経立', :creature],
          ['otto-dori', 'オット鳥', :character],
          ['zashiki-warashi', '座敷童子', :person],
          ['kappa', '河童', :creature]
        ]
      )
      expect(all_beings).to all(have_attributes(work: work, content_warnings: []))
    end
  end

  describe Ihatov::Tono::Person do
    let(:people) { described_class.all }

    it '辞書の順で人物 2 名の ID・名称・出典位置を返すこと returns all person attributes in dictionary order' do
      expect(people.map { |person| [person.id, person.name, person.location] }).to eq(
        [
          %w[sasaki-kizen 佐々木喜善 序・佐々木鏡石（喜善の筆名）],
          %w[zashiki-warashi 座敷童子 第17話]
        ]
      )
      expect(people).to all(have_attributes(work: work, content_warnings: []))
    end
  end

  describe Ihatov::Tono::Character do
    let(:characters) { described_class.all }

    it '登場者の属性を返すこと returns all character attributes' do
      expect(characters).to contain_exactly(
        have_attributes(
          id: 'otto-dori',
          name: 'オット鳥',
          location: '第51話',
          work: work,
          content_warnings: []
        )
      )
    end
  end

  describe Ihatov::Tono::Creature do
    let(:creatures) { described_class.all }

    it '辞書の順で異類 5 体の属性を返すこと returns all creature attributes in dictionary order' do
      expect(creatures.map { |creature| [creature.id, creature.name, creature.location] }).to eq(
        [
          %w[konsesama コンセサマ 第16話],
          %w[gongesama ゴンゲサマ 第110話],
          %w[oshirasama オシラサマ 第69話],
          %w[saru-no-futtachi 猿の経立 第46話],
          %w[kappa 河童 第57話]
        ]
      )
      expect(creatures).to all(have_attributes(work: work, content_warnings: []))
    end
  end

  describe Ihatov::Tono::Quote::Passage do
    let(:passages) { described_class.all }

    context '遠野物語の散文を取得するとき when requesting the Tono passages' do
      it '辞書の順で 12 項目の ID・出典位置を返すこと returns all passage IDs and locations in dictionary order' do
        expect(passages.map { |passage| [passage.id, passage.location] }).to eq(
          [
            %w[tono-three-goddesses 第2話・本文（巻末注を除く）],
            %w[tono-zashiki-warashi 第17話・本文（巻末注を除く）],
            %w[tono-saru-no-futtachi 第46話・本文（巻末注を除く）],
            %w[tono-monogatari-episode-50 第50話],
            %w[tono-monogatari-episode-51 第51話],
            %w[tono-underwater-loom 第54話・本文（巻末注を除く）],
            %w[tono-monogatari-episode-57 第57話],
            %w[tono-red-kappa 第59話・本文（巻末注を除く）],
            %w[tono-mayoiga-bowl 第63話・本文（巻末注を除く）],
            %w[tono-oshirasama 第69話・本文（巻末注を除く）],
            %w[tono-yuki-onna 第103話・本文（巻末注を除く）],
            %w[tono-mirage 第106話・本文（巻末注を除く）]
          ]
        )
      end

      it '全項目を同じ作品と採用版に結び付けること links every passage to the work and adopted edition' do
        expect(passages).to all(
          have_attributes(
            work: work,
            kind: :passage,
            source_url: 'https://www.aozora.gr.jp/cards/001566/files/52504_49667.html'
          )
        )
      end

      it '注意情報のある 2 項目だけを除外できること excludes only the two warned passages' do
        warned_passages = passages.reject { |passage| passage.content_warnings.empty? }
        safe_passages = described_class.where(exclude_content_warnings: true)

        expect(warned_passages.map(&:id)).to eq(%w[tono-mayoiga-bowl tono-oshirasama])
        expect(warned_passages).to all(
          have_attributes(
            content_warnings: satisfy do |warnings|
              warnings.any? && warnings.all?(String)
            end
          )
        )

        expect(safe_passages.size).to eq(10)
        expect(safe_passages).to all(have_attributes(content_warnings: []))
      end
    end
  end
end
