# ihatov

岩手の文学から、ひとこと。

> 虹の脚もとにルビーの絵の具皿があるそうです

宮沢賢治『[虹の絵具皿](https://www.aozora.gr.jp/cards/000081/files/2658_27744.html)』より。

宮沢賢治・石川啄木・『遠野物語』の一節や固有名詞を、Fakerのような手軽さで使うRuby gemです。Fakerには依存しません。

## 開発状況

Ruby **3.4以上**。現在は25作品から131件（詩21、短歌29、俳句2、散文26、地名26、登場者18、擬音語9）を収録しています。
初版の目安は130件程度で、まだ未リリースです。賢治の俳句2句を収録し、啄木の俳句は典拠確認後に追加します。実在地名の座標も典拠確認後に追加します。

仕様は [docs/ihatov-specification.md](docs/ihatov-specification.md)、採用版・編集記録と残作業は [docs/dictionary.md](docs/dictionary.md) を参照してください。

このブランチをチェックアウトした状態で、開発用の依存をインストールします。

```sh
bundle install
bundle exec ruby -Ilib -rihatov -e 'puts Ihatov.quote'
```

## 使い方

```ruby
require 'ihatov'

Ihatov.quote
Ihatov::Kenji.quote
Ihatov::Takuboku.tanka
Ihatov::Tono.passage

place = Ihatov::Kenji::Place.find('カルボナード火山島')
place                  # => "カルボナード火山島"
place.work.title       # => "グスコーブドリの伝記"
place.work.author.name # => "宮沢 賢治"
place.works            # 関連作品すべて
place.sources          # 作品ごとの位置と出典URL
place.source_url       # 先頭の出典URL
place.frozen?          # => true
```

返り値はメタデータを持つ凍結済みの`String`派生オブジェクトです。文章には`text`、地名・登場者には`name`、作品には`title`があります。配列やメタデータも凍結しています。
通常の`String`操作（`upcase`や`+`など）で作った文字列へのメタデータの引き継ぎは保証しません。詩の字下げには`with_indent`を使ってください。

簡便メソッドとクラス側の取得口は同じ抽選処理を使います。

```ruby
Ihatov.work
Ihatov::Work.sample
Ihatov::Kenji::Work.find('銀河鉄道の夜')

Ihatov.poem
Ihatov::Quote.poem
Ihatov::Quote::Poem.sample
Ihatov::Kenji::Quote::Poem.sample

Ihatov::Kenji.person
Ihatov::Kenji.character
Ihatov::Tono.creature
Ihatov::Kenji::Onomatopoeia.sample
```

詩・短歌・俳句・散文はそれぞれ`poem`・`tanka`・`haiku`・`passage`です。`Kenji`・`Takuboku`・`Tono`にも同じ取得口があります。未収録の組み合わせは`Ihatov::NotFoundError`になります。
著者別クラスは検索用の入口であり、返り値は全体APIと共通の値クラスです。`Tono`は柳田國男の全作品ではなく、『遠野物語』の範囲に限定します。

### 一覧・絞り込み

```ruby
Ihatov::Kenji::Work.all
Ihatov::Quote.where(work: '風の又三郎')
Ihatov::Quote.where(author: '石川 啄木', exclude_content_warnings: true)
Ihatov::Place.where(real: true)
```

`author:`には作者オブジェクトまたは姓名を半角スペースで区切った登録名、`work:`には作品オブジェクトまたは登録作品名を指定します。条件はANDで、名前空間の範囲を広げません。
地名などが複数作品に登場する場合、条件は同じ出典作品上で一致する必要があります。返り値の`works`と`sources`には、その対象の全関連作品を保持します。

`all`・`where`は凍結した配列を返し、該当なしなら`[]`。`sample`と`find`は該当なしなら`Ihatov::NotFoundError`、不正な引数は`ArgumentError`です。
`find`は作品名・地名・登場者名の完全一致のみで、`Quote.find`や`entry`は設けません。同名の別対象があるときは年代順で最初の一致を返すため、必要なら`work:`や`author:`も指定してください。

### 字下げ

```ruby
Ihatov.poem                  # 全詩。保存された本文のまま
Ihatov.poem(indent: true)    # 字下げありの詩。1段2スペース
Ihatov.poem(indent: false)   # 字下げなしの詩
Ihatov.poem(indent: "\t")    # 字下げありの詩。1段1タブ
Ihatov.poem(indent: '    ')  # 字下げありの詩。1段4スペース

poem = Ihatov.poem(indent: true)
poem.with_indent("\t")       # 再抽選せず、新しい凍結済みの詩を返す
```

抽選前に対象を絞ります。字下げ指定は空でない半角スペース／タブの文字列です。繰り返し整形しても、元の段数・本文中の空白・空行・出典を維持します。
末尾改行やHTMLは付けません。ルビは括弧で表記します。

### 乱数

```ruby
Ihatov.seed = 1234
Ihatov.quote
Ihatov::Kenji.place

rng = Random.new(5678)
Ihatov.quote(random: rng)
```

各項目を均等に抽選し、作者ごとの重み付けはしません。`random:`は共通の生成器を消費しません。
再現性を保証するのは、同じgem・Rubyバージョン、同じseed・条件・呼び出し順序の範囲だけです。固定対象には`find`、本文まで固定するテストにはfixtureを使ってください。

## 歴史的表現・注意情報

収録する作品には、執筆当時の社会的・歴史的背景を反映し、今日では不適切または差別的と受け取られる可能性のある表現が含まれます。
収録内容は開発者の見解や価値判断を示しません。ルビ・空白など所定の整形を除き、採用版の表記を保持します。

```ruby
Ihatov.quote(exclude_content_warnings: true)
quote = Ihatov.quote
quote.content_warnings # 説明文の配列。注意がなければ []
```

省略時は`false`で、注意情報がある項目も含まれます。注意は収録時の編集判断であり、正式なポリシー違反判定ではありません。
除外機能は、あらゆる利用場面での安全性を保証しません。利用する文脈と対象者に応じて内容をご確認ください。実行時の外部API呼び出しはありません。地名には注意情報の属性を設けません。

## 開発・コントリビューション

> 王さまのお言伝ではあなた様のお手入れしだいで、この珠はどんなにでも立派になると申します。

宮沢賢治『[貝の火](https://www.aozora.gr.jp/cards/000081/files/1942_42611.html)』より。

```sh
bundle install
bundle exec rspec
bundle exec rubocop
bundle exec yard doc --fail-on-warning
gem build ihatov.gemspec
```

### Dockerで開発する

Docker EngineとComposeプラグイン、またはDocker Desktopを用意してください。ホストへのRubyのインストールは不要です。リポジトリのルートで以下を実行します。

```sh
# Linux/macOSではホストとファイルの所有者を合わせる
export LOCAL_UID=$(id -u)
export LOCAL_GID=$(id -g)

# Ruby 3.4と開発用gemを含むイメージを作成
docker compose build dev

# 全テスト／指定ファイルのテスト
docker compose run --rm dev bundle exec rspec
docker compose run --rm dev bundle exec rspec spec/ihatov_spec.rb

# RuboCopによる検査
docker compose run --rm dev bundle exec rubocop

# YARDドキュメントの生成（doc/に出力）
docker compose run --rm dev bundle exec yard doc --fail-on-warning

# gemのビルド（リポジトリ直下に.gemを出力）
docker compose run --rm dev gem build ihatov.gemspec

# Ihatovを読み込んだ対話環境／シェル
docker compose run --rm dev bundle exec irb -Ilib -rihatov
docker compose run --rm dev bash
```

引数なしの `docker compose run --rm dev` でもRSpecを実行します。ソースコードはホストからマウントするため、コードや辞書の編集に再ビルドは不要です。生成されたドキュメント・gem・`Gemfile.lock`もホスト側に残ります。`--rm`はコマンド終了後のコンテナを削除します。

開発用gemはイメージ内にインストールします。`Gemfile`・`Gemfile.lock`・gemspecの依存関係を変更した場合は、`docker compose build dev`で再ビルドしてください。ホストの`.bundle`設定は使用しません。

Ruby 4.0を使う場合は、バージョンを指定して再ビルドします。

```sh
export IHATOV_RUBY_VERSION=4.0
docker compose build --pull dev
docker compose run --rm dev ruby --version
docker compose run --rm dev bundle exec rspec
```

3.4へ戻す場合は `IHATOV_RUBY_VERSION=3.4` にして再ビルドします。イメージは選択したバージョンで置き換わります。Docker設定は開発専用で、配布gemのファイルや実行時依存には含めません。

### 開発方針

RSpecから変更を始め、PRで提案してください。CIはRuby 3.4・4.0でRSpecとgemのビルド・インストール後の利用を確認し、RuboCopとYARDも実行します。新しい安定版Rubyが出たらマトリクスを更新します。
Docker環境についても同じ2バージョンでビルドとRSpec・RuboCop・YARD・gemのビルドを確認します。

テストの説明は `it '〜こと English description' do` の形式で、日本語→英語の順に記述します。条件は `context '〜とき when ...'` とし、「〜場合」は使いません。共通データや取得対象は `let`、条件ごとの準備は `before` で整理します。異なる不正入力を一つの例で順番に検証せず、条件ごとに分けます。乱数など操作順が検証の中心となる処理は、テスト本文に順序を明示します。

YARDコメントは日本語→英語の順に併記します。クラス・メソッドの長い説明は言語ごとに行を分け、引数・戻り値・例外の説明も両言語で記述します。
現時点ではRubyの標準ライブラリのみを使用し、gemspecに実行時の依存gemはありません。
RSpec・RuboCop・YARDは、このリポジトリのGemfileの `development` グループにのみ定義しています。Ihatovを別のプロジェクトで利用するとき、これらがIhatovの依存としてインストールされることはありません。
ここでの `development` はBundlerの依存グループであり、Ihatovの動作モードではありません。通常の `bundle install` は開発用gemもインストールするため、そのままテストやCIで使えます。`require: false` は自動読み込みを抑える指定です。
ActiveSupportは仕様上許可していますが、現在は使用していません。将来導入する場合はgemspecに実行時依存として明記します。

辞書は`data/authors.yml`と作者別の`data/works/*.yml`を直接編集します。作者・作品・ID・出典・分類の決め方は[辞書編集ガイド](docs/dictionary.md)を参照してください。
メタプログラミングによるAPI生成や`send`／`public_send`での振り分けは行いません。

リリースはPRと`v...`タグを使い、当初は手動で行います。RubyGemsへの公開前にgem名の利用可否、典拠・権利関係、辞書の収録範囲を再確認します。このPRでは公開やタグ作成を行いません。

## ライセンス・出典

プログラムは[MIT License](LICENSE)。文学作品の原典・底本・追加注釈の権利確認とは区別します。出典作品・採用版・底本を各項目の`work.edition`と`sources`に記録しています。青空文庫の入力・校正に携わった皆さまに感謝します。

---

> それはとちの実ぐらいあるまんまるの玉で、中では赤い火がちらちら燃えているのです。

宮沢賢治『[貝の火](https://www.aozora.gr.jp/cards/000081/files/1942_42611.html)』より。

> 永久の未完成これ完成である

宮沢賢治『[農民芸術概論綱要](https://www.aozora.gr.jp/cards/000081/files/2386_13825.html)』「結論」より。
