# frozen_string_literal: true

RSpec.describe '同梱辞書 Bundled dictionary' do
  context '啄木の短歌案を取得するとき when requesting the Takuboku tanka candidates' do
    let(:tanka) { Ihatov::Takuboku::Quote::Tanka.all }

    it '不足していた十首を三行で収録すること includes the ten missing complete three-line tanka' do
      ids = %w[kanikakuni-shibutami ishi-wo-mote yawarakani-yanagi kokoroyoku-shigoto ameuri-charumera
               asobini-dete hon-wo-kaitashi natsukashiki-fuyu tochu-nite nanto-naku-kotoshi]
      expect(tanka.map(&:id)).to include(*ids)
      expect(tanka.select { |item| ids.include?(item.id) }.map { |item| item.lines.size }).to eq([3] * 10)
      expect(tanka.count { |item| item.work.title == '悲しき玩具' }).to eq(5)
    end
  end

  context '賢治の追加詩を取得するとき when requesting the additional Kenji poems' do
    let(:poems) { Ihatov::Kenji::Quote::Poem.all }

    it '不足していた七篇を含むこと includes the seven missing poems' do
      expect(poems.map(&:id)).to include('kurakake-no-yuki', 'koi-to-byonetsu', 'koiwai-nojo',
                                        'matsu-no-hari', 'musei-dokoku', 'aomori-banka', 'okhotsk-banka')
      expect(poems.find { |item| item.id == 'matsu-no-hari' }.to_s).to start_with('    さつきのみぞれ')
    end
  end

  context '遠野物語の散文案を取得するとき when requesting the Tono passage candidates' do
    let(:passages) { Ihatov::Tono::Quote::Passage.all }

    it '候補の全十話を含むこと includes all ten candidate episodes' do
      [2, 17, 46, 51, 54, 59, 63, 69, 103, 106].each do |number|
        expect(passages.any? { |item| item.location.match?(/第#{number}話/) }).to be(true)
      end
    end
  end

  context '同梱辞書を読み込むとき when loading the bundled dictionary' do
    it '収録件数と採用版が一致すること exposes expected counts and editions' do
      expect(Ihatov::Quote.all.size).to eq(78)
      expect(Ihatov::Place.all.size).to eq(7)
      expect(Ihatov::Being.all.size).to eq(15)
      expect(Ihatov::Onomatopoeia.all.size).to eq(9)
      expect(Ihatov::Tono.work.edition.aozora_id).to eq(52_504)
      expect(Ihatov::Kenji::Work.find('銀河鉄道の夜').author.name).to eq('宮沢 賢治')
      expect(Ihatov::Work.all).to all(be_frozen)
    end
  end

  context '風の又三郎の擬音語と抜粋を取得するとき when selecting the wind phrase and passage' do
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

  context '散文を一覧取得するとき when listing passages' do
    let(:lines) { Ihatov::Quote::Passage.all.flat_map(&:lines) }

    it '段落頭に字下げを含めないこと omits paragraph indentation' do
      expect(lines).to all(satisfy { |line| !line.match?(/\A[ \t　]/) })
    end
  end

  context '字下げのある詩を取得するとき when selecting indented poems' do
    let(:poem) { Ihatov::Quote::Poem.where(indent: "\t").find { |item| item.id == 'haru-to-shura-sky' } }
    let(:originals) { Ihatov::Quote::Poem.where(indent: true) }

    it '字下げを保持して整形できること preserves indentation when formatting' do
      expect(poem).to include("\t\t聖玻璃（せいはり）の風が行き交ひ")
      expect(originals.size).to be > 1
      expect(poem.with_indent('  ')).to eq(originals.find { |item| item.id == poem.id })
      expect(originals.map(&:id)).to include(Ihatov.poem(indent: "\t").id)
    end
  end

  context '岩手山の詩を取得するとき when selecting the Iwatesan poem' do
    let(:poem) { Ihatov::Kenji::Quote::Poem.where(work: '春と修羅').find { |item| item.id == 'iwatesan-poem' } }

    it '四行の全文とルビを保持すること preserves all four lines and ruby readings' do
      expect(poem.lines(chomp: true)).to eq(
        [
          'そらの散乱反射（さんらんはんしや）のなかに',
          '古ぼけて黒くゑぐるもの',
          'ひかりの微塵系列（みぢんけいれつ）の底に',
          'きたなくしろく澱（よど）むもの'
        ]
      )
      expect(poem).not_to end_with("\n")
      expect(poem).to have_attributes(location: '岩手山・全文', content_warnings: [])
      expect(poem.work.edition.aozora_id).to eq(1058)
      expect(poem.source_url).to eq('https://www.aozora.gr.jp/cards/000081/files/1058_15403.html')
    end
  end

  context '共有地名を取得するとき when selecting shared places' do
    let(:place) { Ihatov::Kenji::Place.find('イーハトーヴ') }

    it '作品ごとの出典を保持すること preserves per-work sources' do
      expect(place.works.map(&:id)).to eq(%w[haru-to-shura gusukobudori-no-denki])
      expect(place.sources.map(&:location)).to eq(['イーハトヴの氷霧', '一 森'])
      expect(Ihatov::Kenji::Place.find('カルボナード火山島').work.title).to eq('グスコーブドリの伝記')
    end
  end

  context '短歌の注意情報を除外するとき when filtering tanka warnings' do
    let(:all_tanka) { Ihatov::Takuboku::Quote::Tanka.all }
    let(:filtered) { Ihatov::Takuboku::Quote::Tanka.where(exclude_content_warnings: true) }

    it '注意のある項目だけを除外すること excludes only warned entries' do
      expect(all_tanka.size).to eq(28)
      expect(filtered.size).to eq(27)
      expect(filtered).to all(have_attributes(content_warnings: []))
      expect(Ihatov::Quote.all).to all(satisfy { |text| !text.end_with?("\n") })
    end
  end

  context 'ふるさとを詠む短歌を取得するとき when selecting hometown tanka' do
    let(:tanka) { Ihatov::Takuboku::Quote::Tanka.where(work: '一握の砂') }
    let(:namari) { tanka.find { |item| item.id == 'furusato-no-namari' } }
    let(:yama) { tanka.find { |item| item.id == 'furusato-no-yama' } }

    it '採用版の表記と三行の改行を保持すること preserves the edition text and three-line layout' do
      expect(namari).to eq("ふるさとの訛（なまり）なつかし\n停車場（ていしやば）の人ごみの中に\nそを聴（き）きにゆく")
      expect(yama).to eq("ふるさとの山に向ひて\n言ふことなし\nふるさとの山はありがたきかな")
    end

    it '二首を煙の第二節と採用版に関連付けること links both tanka to Kemuri section two and the edition' do
      expect([namari, yama]).to all(have_attributes(location: '煙・二', content_warnings: []))
      expect([namari, yama].map(&:work)).to all(eq(Ihatov::Takuboku::Work.find('一握の砂')))
      expect([namari, yama].map(&:source_url).uniq).to eq(['https://www.aozora.gr.jp/cards/000153/files/816_15786.html'])
    end
  end

  context 'やまなしの項目を取得するとき when selecting Yamanashi entries' do
    let(:opening) { Ihatov::Kenji::Quote::Passage.where(work: 'やまなし').find { |item| item.id == 'yamanashi-may' } }

    it '各項目が確認済みの出典に結び付くこと connects entries to verified sources' do
      expect(Ihatov::Kenji::Creature.find('クラムボン').work.edition.aozora_id).to eq(46_605)
      expect(Ihatov::Kenji::Onomatopoeia.where(work: 'やまなし')).to contain_exactly('かぷかぷ', 'トブン')
      expect(opening).to include('かぷかぷ', 'そのなめらかな天井（てんじょう）を')
    end
  end

  context '銀河鉄道の夜の冒頭を取得するとき when selecting the opening of Night on the Galactic Railroad' do
    let(:opening) { Ihatov::Kenji::Quote::Passage.where(work: '銀河鉄道の夜').first }
    let(:characters) { Ihatov::Kenji::Person.where(work: '銀河鉄道の夜') }

    it '指定された二段落とルビを保持すること preserves the selected two paragraphs and readings' do
      expect(opening).to have_attributes(id: 'ginga-tetsudo-no-yoru-opening', location: '一 午後の授業・冒頭2段落')
      expect(opening.lines.size).to eq(2)
      expect(opening).to start_with('「ではみなさんは、そういうふうに川だと言（い）われたり、')
      expect(opening).to include("みんなに問（と）いをかけました。\nカムパネルラが手をあげました。")
      expect(opening).to end_with('なんだかどんなこともよくわからないという気持（きも）ちがするのでした。')
    end

    it '本文と登場者の採用版を統一すること uses one edition for the passage and characters' do
      expect(opening.work.edition.aozora_id).to eq(43_737)
      expect(characters.map(&:id)).to eq(%w[giovanni campanella])
      expect([opening, *characters]).to all(have_attributes(work: opening.work))
      expect([opening, *characters].map(&:source_url).uniq)
        .to eq(['https://www.aozora.gr.jp/cards/000081/files/43737_19215.html'])
    end
  end

  context 'ポラーノの広場の抜粋を取得するとき when selecting the Polano Square passage' do
    let(:passage) { Ihatov::Kenji::Quote::Passage.where(work: 'ポラーノの広場').first }

    it '指定された二段落の範囲と表記を保持すること preserves the selected two paragraphs and spelling' do
      expect(passage).to have_attributes(id: 'polano-ihatovo', content_warnings: [])
      expect(passage.lines.size).to eq(2)
      expect(passage).to start_with('あのイーハトーヴォのすきとおった風、')
      expect(passage).to include("郊外のぎらぎらひかる草の波。\nまたそのなかで")
      expect(passage).to end_with('しずかにあの年のイーハトーヴォの五月から十月までを書きつけましょう。')
      expect(passage.work.edition.aozora_id).to eq(1935)
      expect(passage.source_url).to eq('https://www.aozora.gr.jp/cards/000081/files/1935_19925.html')
    end
  end

  context '雨ニモマケズの全文を取得するとき when selecting the complete Ame ni mo Makezu' do
    let(:poem) { Ihatov::Kenji::Quote::Poem.where(work: '〔雨ニモマケズ〕').first }

    it '原文の文字と末尾の題目を保持すること preserves original characters and the closing invocations' do
      expect(poem.lines.size).to eq(38)
      expect(poem).to start_with("雨ニモマケズ\n風ニモマケズ\n")
      expect(poem).to include('決シテ瞋ラズ', '野原ノ松ノ林ノ䕃ノ', '小サナ萓ブキノ小屋ニヰテ')
      expect(poem).to include('行ッテソノ稲ノ朿ヲ負ヒ', 'ヒドリノトキハナミダヲナガシ')
      expect(poem).to include("ワタシハナリタイ\n\n南無無辺行菩薩\n")
      expect(poem).to end_with("南無浄行菩薩\n南無安立行菩薩")
      expect(poem).not_to include('［＃', '<img')
      expect(poem.work.edition.aozora_id).to eq(45_630)
      expect(poem.indented?).to be(false)
    end

    it '注意情報による除外に対応すること supports content warning exclusion' do
      expect(poem.content_warnings).to eq(['人を蔑む呼称「デクノボー」が含まれます。'])
      expect(Ihatov::Kenji::Quote::Poem.where(work: poem.work, exclude_content_warnings: true)).to eq([])
    end
  end

  context 'よだかの星の冒頭を取得するとき when selecting the Nighthawk Star opening' do
    let(:opening) { Ihatov::Kenji::Quote::Passage.where(work: 'よだかの星').first }

    it '指定の五段落と出典を保持すること preserves the selected five paragraphs and source' do
      expect(opening).to have_attributes(id: 'yodaka-no-hoshi-opening', location: '冒頭5段落')
      expect(opening.lines.size).to eq(5)
      expect(opening).to start_with("よだかは、実にみにくい鳥です。\n")
      expect(opening).to include('味噌（みそ）', '一間（いっけん）', '工合（ぐあい）', 'そっ方（ぽ）')
      expect(opening).to end_with('いつでもよだかのまっこうから悪口をしました。')
      expect(opening.work.edition.aozora_id).to eq(473)
      expect(opening.content_warnings).to eq(['容姿を理由にした侮蔑や排斥、いじめの描写があります。'])
      expect(Ihatov::Kenji::Quote::Passage.where(work: opening.work, exclude_content_warnings: true)).to eq([])
    end
  end

  context 'ほんとうのさいわいの対話を取得するとき when selecting the true happiness dialogue' do
    let(:passages) { Ihatov::Kenji::Quote::Passage.where(work: '銀河鉄道の夜') }
    let(:dialogue) { passages.find { |item| item.id == 'ginga-hontou-no-saiwai' } }

    it '採用版の表記と章へのリンクを保持すること preserves the adopted edition and chapter link' do
      expect(dialogue.lines.size).to eq(6)
      expect(dialogue).to start_with('「カムパネルラ、また僕（ぼく）たち二人（ふたり）きりになったねえ、')
      expect(dialogue).to include("「けれどもほんとうのさいわいはいったいなんだろう」\nジョバンニが言（い）いました。")
      expect(dialogue).to end_with('ふうと息（いき）をしながら言（い）いました。')
      expect(dialogue.work.edition.aozora_id).to eq(43_737)
      expect(dialogue.source_url).to eq('https://www.aozora.gr.jp/cards/000081/files/43737_19215.html#midashi90')
    end

    it '注意情報を除外しても冒頭は取得できること retains the opening when warnings are excluded' do
      expect(dialogue.content_warnings).not_to be_empty
      expect(Ihatov::Kenji::Quote::Passage.where(work: dialogue.work, exclude_content_warnings: true).map(&:id))
        .to eq(['ginga-tetsudo-no-yoru-opening'])
    end
  end

  context '注文の多い料理店の序を取得するとき when selecting the Restaurant preface' do
    let(:work) { Ihatov::Kenji::Work.find('『注文の多い料理店』序') }
    let(:passage) { Ihatov::Kenji::Quote::Passage.where(work: work).first }

    it '指定された四段落とルビを保持すること preserves the selected four paragraphs and readings' do
      expect(passage).to have_attributes(id: 'chumon-preface-opening', location: '序・冒頭4段落')
      expect(passage.lines.size).to eq(4)
      expect(passage).to start_with('わたしたちは、氷砂糖をほしいくらいもたないでも、')
      expect(passage).to include('桃（もも）', '羅紗（らしゃ）')
      expect(passage).to end_with('虹（にじ）や月あかりからもらってきたのです。')
      expect(passage.content_warnings).to eq([])
    end

    it '序文の採用版と初出年を保持すること records the preface edition and first publication year' do
      expect(work).to have_attributes(id: 'chumon-no-oi-ryoriten-preface', announced_year: 1924)
      expect(work.edition.aozora_id).to eq(43_736)
      expect(passage.source_url).to eq('https://www.aozora.gr.jp/cards/000081/files/43736_17656.html')
    end
  end

  context '新刊案内のイーハトヴの説明を取得するとき when selecting the announcement description of Ihatov' do
    let(:work) { Ihatov::Kenji::Work.find('『注文の多い料理店』新刊案内') }
    let(:passage) { Ihatov::Kenji::Quote::Passage.where(work: work).first }

    it '新字新仮名の採用版と二段落を保持すること preserves the modern-kana edition and two paragraphs' do
      expect(work).to have_attributes(id: 'chumon-no-oi-ryoriten-announcement', announced_year: 1924)
      expect(work.edition.aozora_id).to eq(43_734)
      expect(passage).to have_attributes(id: 'ihatov-dreamland', content_warnings: [])
      expect(passage.lines.size).to eq(2)
      expect(passage).to start_with('イーハトヴは一つの地名である。しいて、')
      expect(passage).to include("イヴン王国の遠い東と考えられる。\nじつにこれは著者の心象中に、")
      expect(passage).to end_with('実在（じつざい）したドリームランドとしての日本岩手県である。')
      expect(passage).not_to include('<strong', '［＃')
      expect(passage.source_url).to eq('https://www.aozora.gr.jp/cards/000081/files/43734_17913.html')
    end
  end

  context '農民芸術概論綱要の序論を取得するとき when selecting the introduction to Peasant Art' do
    let(:passage) { Ihatov::Kenji::Quote::Passage.where(work: '農民芸術概論綱要').first }

    it '指定の十行と旧仮名と行中の空白を保持すること preserves ten lines, historical spelling, and internal spaces' do
      expect(passage).to have_attributes(id: 'nomin-geijutsu-introduction', content_warnings: [])
      expect(passage.lines.size).to eq(10)
      expect(passage).to start_with("おれたちはみな農民である　ずゐぶん忙がしく仕事もつらい\n")
      expect(passage).to include('世界がぜんたい幸福にならないうちは個人の幸福はあり得ない')
      expect(passage).to end_with('われらは世界のまことの幸福を索ねよう　求道すでに道である')
      expect(passage.work.edition.aozora_id).to eq(2386)
      expect(passage.source_url).to eq('https://www.aozora.gr.jp/cards/000081/files/2386_13825.html')
    end
  end

  context '雪渡りの登場者を取得するとき when selecting a Yukiwatari character' do
    let(:character) { Ihatov::Kenji::Character.find('紺三郎') }

    it '確認済みの採用版に結び付くこと links to the verified edition' do
      expect(character.work.edition.aozora_id).to eq(45_679)
    end
  end

  context '遠野物語の登場者を取得するとき when selecting Tono Monogatari beings' do
    let(:oshirasama) { Ihatov::Tono::Creature.find('オシラサマ') }

    it '採用版と話数に結び付くこと links to the edition and tale number' do
      expect(Ihatov::Tono::Creature.find('猿の経立').location).to eq('第46話')
      expect(oshirasama).to have_attributes(id: 'oshirasama', location: '第69話')
      expect(oshirasama.work.edition.aozora_id).to eq(52_504)
    end
  end

  context '実在地名を取得するとき when selecting real places' do
    let(:places) { Ihatov::Place.where(real: true) }

    it '実在性と座標の未登録を区別すること distinguishes real places from available coordinates' do
      expect(Ihatov::Takuboku::Place.find('不来方城').real).to be(true)
      expect(places).to all(have_attributes(coordinates: nil))
    end
  end

  context '同梱作品を一覧取得するとき when listing bundled works' do
    it '発表年または刊行年で並ぶこと orders works by announcement or publication year' do
      expect(Ihatov::Work.all.first.title).to eq('一握の砂')
      expect(Ihatov::Kenji::Work.all.first.title).to eq('雪渡り')
    end
  end

  context '浄土ヶ浜の短歌を取得するとき when selecting the Jodogahama tanka' do
    let(:tanka) { Ihatov::Kenji::Quote::Tanka.all.find { |item| item.id == 'uruhashino-umi' } }

    it '指定の歌と宮古市の出典を保持すること preserves the requested tanka and municipal source' do
      expect(tanka.to_s).to eq("うるはしの\n海のビロード 昆布らは\n寂光のはまに 敷かれひかりぬ")
      expect(tanka.source_url).to start_with('https://www.city.miyako.iwate.jp/')
      expect(tanka.work.edition.aozora_id).to be_nil
    end
  end

  context '賢治の俳句を取得するとき when requesting Kenji haiku' do
    it '確認した二句と出典を返すこと returns two verified haiku and their source' do
      expect(Ihatov::Kenji::Quote::Haiku.all.size).to eq(2)
      expect(Ihatov::Kenji::Quote::Haiku.all.first.work.edition.aozora_id).to be_nil
      expect(Ihatov::Kenji::Quote::Haiku.all.map(&:to_s)).to include('鳥屋根を歩く音して明けにけり')
    end
  end

  context '永訣の朝を取得するとき when selecting Eiketsu no Asa' do
    let(:poem) { Ihatov::Kenji::Quote::Poem.all.find { |item| item.id == 'eiketsu-no-asa' } }

    it '指定の七行と二つの括弧行の字下げを保持すること preserves the seven lines and indented refrains' do
      expect(poem.lines(chomp: true)).to eq(
        [
          'けふのうちに',
          'とほくへいつてしまふわたくしのいもうとよ',
          'みぞれがふつておもてはへんにあかるいのだ',
          '      （あめゆじゆとてちてけんじや）',
          'うすあかくいつそう陰惨（いんざん）な雲から',
          'みぞれはびちよびちよふつてくる',
          '      （あめゆじゆとてちてけんじや）'
        ]
      )
      expect(poem.with_indent("\t").lines[3]).to start_with("\t\t\t（")
      expect(poem.source_url).to end_with('#midashi1178')
    end
  end

  context '星めぐりの歌を取得するとき when selecting Hoshimeguri no Uta' do
    let(:poem) { Ihatov::Kenji::Quote::Poem.where(work: '星めぐりの歌').first }

    it '全歌詞と連間の空行と行中の空白を保持すること preserves all lyrics, stanza breaks, and internal spaces' do
      expect(poem.split("\n\n").map { |stanza| stanza.lines.size }).to eq([4, 4, 4])
      expect(poem).to start_with("あかいめだまの　さそり\nひろげた鷲の　　つばさ\n")
      expect(poem).to include('五つのばした　　ところ。')
      expect(poem).to end_with('そらのめぐりの　めあて。')
      expect(poem).not_to end_with("\n")
      expect(poem.work.edition.aozora_id).to eq(46_268)
    end
  end
end
