# iPhone Duo対応の検証

## 自動検証

Xcode 27.1 / iOS 27.1 SDKでビルドします。以下は今回の変更に関係するテストを選択するコマンドです。`-destination`のデバイス名は、導入済みのシミュレータに置き換えてください。

```sh
xcodebuild -project azooKey.xcodeproj -scheme DuoFlickTests \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -only-testing:KeyboardViewsTests \
  -only-testing:AzooKeyUtilsTests/DuoFlickInteractionTests \
  -only-testing:AzooKeyUtilsTests/DuoFlickLayoutDefaultsTests \
  -only-testing:AzooKeyUtilsTests/ResolvedKeyboardSizeTests \
  CODE_SIGNING_ALLOWED=NO test

xcodebuild -project azooKey.xcodeproj -scheme DuoAppTests \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -only-testing:azooKeyUITests/DuoAdaptationUITests \
  -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM= test
```

| 対象 | 検証範囲 |
| --- | --- |
| `DuoFlickLayoutTests` | 600pt境界、左右の幅・間隔、異常な保存値、標準の高さ・キーサイズ |
| `CompactFlickLayoutTests` | 閉じた縦画面の270pt上限、7pt間隔と余白、閉じた横画面の200pt上限 |
| `KeyboardPresentationTests` | 入力ウィンドウが横長でも画面シーンの縦向きを維持すること、閉じた表示と見開きの識別 |
| `ResolvedKeyboardSizeTests` | 古い版・異なる表示のキャッシュを破棄し、同じ表示の寸法だけを使用すること |
| `ReservedRegionLayoutTests` | 中央／偏った折り目、カメラ、領域外・重複・無効な予約領域、手動で低くした高さ、完全に遮られた領域 |
| `DuoFlickInteractionTests` | 重なった左右フリック、候補バー境界のヒット判定、開閉・回転時の候補とタブの保持、移動するキーへのタッチのキャンセル、QWERTY／カスタムタブへの復帰 |
| `DuoFlickLayoutDefaultsTests` | 初期の狭い設定からの一度だけの移行と、その後の手動調整の保持 |
| `DuoAdaptationUITests` | 設定画面の縦・横表示、フリック編集の選択・入力値の保持。変更したラベルは終了時に復元 |

2026-10-24の確認結果:

- iPhone 18 Pro / iOS 27.0: 選択したパッケージテスト64件が成功。
- iPhone 16 Pro / iOS 18.5: 62件が成功、UIKitのiOS 27専用タッチ処理2件をスキップ。
- iPhone 18 Pro / iOS 27.0: UIテスト2件が成功。
- iPad mini / iOS 27.0: 広い画面でUIテスト2件が成功。
- アプリ本体とキーボード拡張: シミュレータ・iOS 27.1実機向けビルドが成功。
- Duo実機（ビルド6）: 利用者より、一連のDuo実機テスト完了の報告を受領（2026-10-24）。
- CI追加後の再確認: Releaseの実機向けビルド、パッケージテスト64件、iPhone／iPadのUIテスト各2件が成功。
- 一時コピーで新SDK向けのコンパイル条件を無効にし、フォールバックのみのReleaseビルドも成功（使用コンパイラ・SDKは27.1）。
- SwiftLint 0.65.1: エラー0件。上流の基点と比較して新規の違反0件（既存の警告は残す）。
- actionlint 1.7.12、シェル構文、Xcodeプロジェクト形式、`git diff --check`: 成功。

予約領域を渡すテストは幾何計算を検証します。Duoの姿勢に応じてOSが返す実際の領域や、iOS 27.1の`ArrangementView`・縦向きバーの表示を確認したことにはなりません。今回利用できたシミュレータはiOS 27.0までで、Duo機種はそのランタイムと非互換でした。iOS 18.5／27.0のUIテストは旧OS向けフォールバックを検証しています。Duo固有の実機動作は、これらの自動テストとは別に利用者の実機テスト完了報告で補完しています。

## Duo実機での確認

実機操作は利用者が担当し、ビルド6で一連のDuo実機テストを完了したとの報告を受領しました。以下は確認手順の一覧です。

- 閉じた画面のサイズ・表示。ビルド6で利用者の実機確認済み。
- 閉じた横画面が誤って2面表示にならない。
- 閉じた画面、内側の全開、部分的に折った姿勢を、縦横それぞれで切り替える。設定の現在位置、選択中のタブ、編集中のラベル・文章を保持する。
- 内側の縦・横の折り目とカメラ領域に、キー・変換候補・設定の重要な操作が重ならない。バーが縦に配置されても戻る・保存・キャンセル・キーの種類選択へアクセスできる。
- 左右の「あ・か」などを交互／同時にフリックし、濁点、小文字、句読点、削除、空白、確定・検索を確認する。操作途中に開閉して余分な文字が確定しない。
- 上段の短い変換候補を上端・下端・候補間付近から選ぶ。候補を拡大し、スクロール・候補選択・閉じるも確認する。
- 自動幅、手動幅、中央間隔、既存の高さ調整を変更し、開き直しても設定を保つ。標準270ptで純正との左右余白・高さを比較する。
- かな・英字・数字フリック、QWERTY、カスタムタブ、片手モードを切り替える。Duoフリック無効時は従来の配列へ戻る。
- 使い方・設定・着せ替え・拡張、キー／タブ編集、ユーザ辞書、画像選択・トリミングを開閉・回転しながら使う。
- ライト／ダーク、大きい文字、VoiceOver、フルアクセスの有無、外付けキーボードの接続を確認する。

個人の署名情報、実機識別子、App Groupの個人用変更は共有する差分に含めません。

## CI

- `build-on-push.yml`: 既存の`Xcode Build`をXcode 26.3で実行し、旧SDKのコンパイル互換性を確認します。別の`Duo Build and Tests (Xcode 27.1)`は、公式の`xcode-27`ホストランナーでReleaseビルド、上記のパッケージテスト、iPhone 18 ProとiPad miniのUIテストを実行し、ログと`.xcresult`を保存します。
- `SwiftLint`: `.github/scripts/swiftlint.sh`で公式バイナリの版とSHA-256を固定します。自動修正は行いません。既存のXcodeビルドフェーズもCIでは読み取りのみです。
- `swift.yml`: 既存のmacOS向けパッケージビルド・CustardKitテストをXcode 26.3へ固定します。キャッシュはOS・CPU・Xcode版で分けます。
- `CodeQL`: `main`向けPRでも実行します。現在の[対応表](https://codeql.github.com/docs/codeql-overview/supported-languages-and-frameworks/)ではSwift 6.3までのため、Swift 6.4を使うXcode 27.1とは分け、Xcode 26.3で解析します。27.1専用APIの分岐はこの解析に含まれず、Duoビルド側でコンパイルします。
- App Store Connect用ワークフローもDuoのAPIを含むXcode 27.1へ揃えます。配布条件と署名用Secretsは変更しません。

2026-10-24時点の[公式ランナー](https://github.com/actions/runner-images/blob/main/images/macos/xcode-27-arm64-Readme.md)は、Xcode 27.1とiOS 27.1 SDKを含み、シミュレータのランタイムはiOS 27.0です。そのためCIでも27.1専用の表示自体は実機確認を補完するものです。

GitHub上のワークフロー実行、CodeQLの実解析、Xcode 26.3そのものでの実行はPush後に確認します。ローカルにはXcode 27.1のみがあり、CI全体の成功を確認したものではありません。

ローカルで固定版のlintを再現するコマンド:

```sh
bash .github/scripts/swiftlint.sh
```
