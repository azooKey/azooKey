# iPhone Duo対応の検証

## 自動検証

Xcode 27.1 / iOS 27.1 SDKでビルドします。以下は今回の変更に関係するテストを選択するコマンドです。`-destination`のデバイス名は、導入済みのシミュレータに置き換えてください。

```sh
xcodebuild -project azooKey.xcodeproj -scheme DuoFlickTests \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -only-testing:KeyboardViewsTests \
  -only-testing:AzooKeyUtilsTests/DuoFlickInteractionTests \
  -only-testing:AzooKeyUtilsTests/DuoFlickLayoutDefaultsTests \
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
| `ReservedRegionLayoutTests` | 中央／偏った折り目、カメラ、領域外・重複・無効な予約領域、手動で低くした高さ、完全に遮られた領域 |
| `DuoFlickInteractionTests` | 重なった左右フリック、候補バー境界のヒット判定、開閉・回転時の候補とタブの保持、移動するキーへのタッチのキャンセル、QWERTY／カスタムタブへの復帰 |
| `DuoFlickLayoutDefaultsTests` | 初期の狭い設定からの一度だけの移行と、その後の手動調整の保持 |
| `DuoAdaptationUITests` | 設定画面の縦・横表示、フリック編集の選択・入力値の保持。変更したラベルは終了時に復元 |

2026-10-24の確認結果:

- iPhone 18 Pro / iOS 27.0: 選択したパッケージテスト49件が成功。
- iPhone 16 Pro / iOS 18.5: 48件が成功、UIKitのiOS 27専用タッチ処理1件をスキップ。
- iPhone 18 Pro / iOS 27.0: UIテスト2件が成功。
- iPad mini / iOS 27.0: 広い画面でUIテスト2件が成功。
- アプリ本体とキーボード拡張: シミュレータ・iOS 27.1実機向けビルドが成功。
- SwiftLint: 検証環境に未導入のため未実行。

予約領域を渡すテストは幾何計算を検証します。Duoの姿勢に応じてOSが返す実際の領域や、iOS 27.1の`ArrangementView`・縦向きバーの表示を確認したことにはなりません。今回利用できたシミュレータはiOS 27.0までで、Duo機種はそのランタイムと非互換でした。iOS 18.5／27.0のUIテストは旧OS向けフォールバックを検証しています。

## Duo実機での確認

キーボード拡張とアプリの両方を更新し、Duoフリックを有効にして確認します。以下は実機操作による確認が必要な項目で、チェック前の状態を合格として扱いません。

- [ ] 閉じた画面、内側の全開、部分的に折った姿勢を、縦横それぞれで切り替える。設定の現在位置、選択中のタブ、編集中のラベル・文章を保持する。
- [ ] 内側の縦・横の折り目とカメラ領域に、キー・変換候補・設定の重要な操作が重ならない。バーが縦に配置されても戻る・保存・キャンセル・キーの種類選択へアクセスできる。
- [ ] 左右の「あ・か」などを交互／同時にフリックし、濁点、小文字、句読点、削除、空白、確定・検索を確認する。操作途中に開閉して余分な文字が確定しない。
- [ ] 上段の短い変換候補を上端・下端・候補間付近から選ぶ。候補を拡大し、スクロール・候補選択・閉じるも確認する。
- [ ] 自動幅、手動幅、中央間隔、既存の高さ調整を変更し、開き直しても設定を保つ。標準270ptで純正との左右余白・高さを比較する。
- [ ] かな・英字・数字フリック、QWERTY、カスタムタブ、片手モードを切り替える。Duoフリック無効時は従来の配列へ戻る。
- [ ] 使い方・設定・着せ替え・拡張、キー／タブ編集、ユーザ辞書、画像選択・トリミングを開閉・回転しながら使う。
- [ ] ライト／ダーク、大きい文字、VoiceOver、フルアクセスの有無、外付けキーボードの接続を確認する。

個人の署名情報、実機識別子、App Groupの個人用変更は共有する差分に含めません。
