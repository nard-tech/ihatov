# frozen_string_literal: true

RSpec.describe Ihatov::Takuboku do
  let(:ichiaku_no_suna) { Ihatov::Takuboku::Work.find('一握の砂') }
  let(:kanashiki_gangu) { Ihatov::Takuboku::Work.find('悲しき玩具') }

  describe Ihatov::Takuboku::Work do
    let(:works) { described_class.all }

    it '辞書の順で 2 作品と採用版の情報を返すこと returns both works and editions in dictionary order' do
      attributes = works.map do |work|
        {
          id: work.id,
          title: work.title,
          published_year: work.published_year,
          edition: { aozora_id: work.edition.aozora_id, url: work.edition.url }
        }
      end

      expect(attributes).to eq(
        [
          {
            id: 'ichiaku-no-suna',
            title: '一握の砂',
            published_year: 1910,
            edition: { aozora_id: 816, url: 'https://www.aozora.gr.jp/cards/000153/card816.html' }
          },
          {
            id: 'kanashiki-gangu',
            title: '悲しき玩具',
            published_year: 1912,
            edition: { aozora_id: 815, url: 'https://www.aozora.gr.jp/cards/000153/card815.html' }
          }
        ]
      )
      expect(works).to all(have_attributes(author: have_attributes(name: '石川 啄木')))
    end
  end

  describe Ihatov::Takuboku::Place do
    let(:places) { described_class.all }

    it '辞書の順で 6 地名の ID・名称・出典位置を返すこと returns all place attributes in dictionary order' do
      expect(places.map { |place| [place.id, place.name, place.location] }).to eq(
        [
          %w[kozukata-jo 不来方城 煙・一「不来方のお城の草に寝ころびて」],
          %w[shibutami 渋民 「かにかくに渋民村は恋しかり」],
          %w[koma 好摩 「霧ふかき好摩の原の」],
          %w[kitakami-gawa 北上川 「北上の岸辺目に見ゆ」],
          %w[ueno-eki 上野駅 煙・二「ふるさとの訛なつかし」],
          %w[hotokuji 宝徳寺 作者ゆかり・渋民で幼少時代を過ごした寺]
        ]
      )
    end

    it '全地名を実在地として『一握の砂』に結び付けること links every real place to Ichiaku no Suna' do
      expect(places).to all(have_attributes(real: true, work: ichiaku_no_suna))
      expect(places.first(5)).to all(
        have_attributes(source_url: 'https://www.aozora.gr.jp/cards/000153/files/816_15786.html')
      )
      expect(places.last.source_url).to include('city.morioka.iwate.jp')
    end
  end

  describe Ihatov::Takuboku::Quote::Tanka do
    let(:tankas) { described_class.all }

    context '啄木の短歌を取得するとき when requesting the Takuboku tanka' do
      it '辞書の順で 28 首の ID・出典位置を返すこと returns all tanka IDs and locations in dictionary order' do
        expect(tankas.size).to eq(28)
        expect(tankas.map { |tanka| [tanka.id, tanka.location] }).to eq(
          [
            %w[tokai-no-kojima 我を愛する歌・冒頭],
            %w[inochinaki-suna 我を愛する歌],
            %w[dai-toiu-ji 我を愛する歌],
            %w[tawamure-ni-haha 我を愛する歌],
            %w[shittorito-namida 我を愛する歌],
            %w[namida-namida 我を愛する歌],
            %w[mare-ni-aru 我を愛する歌],
            %w[nantonaku-kisha 我を愛する歌],
            %w[yawarakani-yuki 我を愛する歌],
            %w[kokoroyoku-hito 我を愛する歌],
            %w[kokoroyoki-tsukare 我を愛する歌],
            %w[hatarakedo 我を愛する歌],
            %w[suisho-no-tama 我を愛する歌],
            %w[oinaru-suisho 我を愛する歌],
            %w[tomo-ga-mina 我を愛する歌],
            %w[kozukata-no-oshiro 煙・一],
            %w[furusato-no-namari 煙・二],
            %w[furusato-no-yama 煙・二],
            %w[kanikakuni-shibutami 初句：かにかくに渋民村（しぶたみむら）は恋しかり],
            %w[ishi-wo-mote 初句：石をもて追はるるごとく],
            %w[yawarakani-yanagi 初句：やはらかに柳あをめる],
            %w[kokoroyoku-shigoto 初句：こころよく],
            %w[ameuri-charumera 初句：飴売（あめうり）のチャルメラ聴けば],
            %w[asobini-dete 初句：遊びに出て子供かへらず、],
            %w[hon-wo-kaitashi 初句：本を買ひたし、本を買ひたしと、],
            %w[natsukashiki-fuyu 初句：なつかしき冬の朝かな。],
            %w[tochu-nite 初句：途中にて乗換（のりかへ）の電車なくなりしに、],
            %w[nanto-naku-kotoshi 初句：何となく、]
          ]
        )
        expect(tankas).to all(satisfy { |tanka| tanka.lines.size == 3 })
      end

      it '作品ごとの収録数と共通属性を返すこと returns counts and common attributes for each work' do
        ichiaku_tankas = described_class.where(work: ichiaku_no_suna)
        kanashiki_tankas = described_class.where(work: kanashiki_gangu)

        expect(ichiaku_tankas.size).to eq(23)
        expect(ichiaku_tankas).to all(
          have_attributes(
            work: ichiaku_no_suna,
            kind: :tanka,
            source_url: 'https://www.aozora.gr.jp/cards/000153/files/816_15786.html'
          )
        )

        expect(kanashiki_tankas.size).to eq(5)
        expect(kanashiki_tankas).to all(
          have_attributes(
            work: kanashiki_gangu,
            kind: :tanka,
            source_url: 'https://www.aozora.gr.jp/cards/000153/files/815_20544.html'
          )
        )
      end

      context '短歌の注意情報を除外するとき when filtering tanka warnings' do
        let(:warned_tankas) { tankas.reject { |tanka| tanka.content_warnings.empty? } }
        let(:safe_tankas) { described_class.where(exclude_content_warnings: true) }

        it '注意情報のある 1 首だけを除外すること excludes only the warned tanka' do
          expect(warned_tankas).to contain_exactly(
            have_attributes(
              id: 'dai-toiu-ji',
              content_warnings: ['自死を考える場面への言及があります。']
            )
          )
          expect(safe_tankas.size).to eq(27)
          expect(safe_tankas).to all(have_attributes(content_warnings: []))
        end
      end

      context 'ふるさとを詠む短歌を取得するとき when selecting hometown tanka' do
        let(:namari) { described_class.where(work: ichiaku_no_suna).find { |tanka| tanka.id == 'furusato-no-namari' } }
        let(:yama) { described_class.where(work: ichiaku_no_suna).find { |tanka| tanka.id == 'furusato-no-yama' } }

        it '採用版の表記と 3 行の改行を保持すること preserves the edition text and three-line layout' do
          expect(namari).to eq("ふるさとの訛（なまり）なつかし\n停車場の人ごみの中に\nそを聴きにゆく")
          expect(yama).to eq("ふるさとの山に向ひて\n言ふことなし\nふるさとの山はありがたきかな")
        end

        it '歌と関連地名を同じ作品に結び付けること links the tanka and related place to the same work' do
          expect([namari, yama]).to all(
            have_attributes(work: ichiaku_no_suna, location: '煙・二', content_warnings: [])
          )
          expect(Ihatov::Takuboku::Place.find('上野駅').work).to eq(namari.work)
        end
      end
    end
  end
end
