# iPhone Duoのレイアウト調整の検証

左右フリックを除いた差分の検証手順です。分離前の実機テストやCIの成功を、この差分での再検証結果としては扱いません。

## 自動テスト

```sh
xcodebuild test -project azooKey.xcodeproj -scheme DuoLayoutTests \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' \
  -only-testing:KeyboardViewsTests \
  -only-testing:AzooKeyUtilsTests/KeyboardLayoutInteractionTests \
  -only-testing:AzooKeyUtilsTests/ResolvedKeyboardSizeTests \
  CODE_SIGNING_ALLOWED=NO

xcodebuild test -project azooKey.xcodeproj -scheme DuoAppTests \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' \
  -only-testing:azooKeyUITests/DuoAdaptationUITests \
  -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM=
```

KeyboardPresentationTestsでシーンの向きを優先し、不明時だけ画面寸法・直前の向きへフォールバックすることを確認します。ReservedRegionLayoutTestsでは候補・独自コントロールの表示領域計算を確認します。KeyboardLayoutInteractionTestsではリサイズ後のタブ・候補の保持と短い候補の操作領域を確認します。ResolvedKeyboardSizeTestsでは向き別のキャッシュと無効な寸法の除外を確認します。

DuoAdaptationUITestsは既存のカスタムキー編集画面への遷移、回転後の操作領域、選択・入力値の保持を検証します。左右フリックの新設定には依存しません。

## Simulatorでの比較

[変更前後のスクリーンショット](iphone-duo-screenshots.md)は、PRの基点mainと分離後のコードを、同じXcode・同じDuo Simulatorランタイムでビルドして撮影します。App Store配信バイナリとの比較ではありません。画像は加工せず、画面・姿勢・操作条件を揃えます。

## CI

Xcode 26.3の互換ビルド、Xcode 27.1のビルドと回帰・UIテスト、固定版SwiftLintを実行します。UIテストはiPhoneとiPadの2種類で実行します。SwiftとCodeQLも既存のワークフローで実行します。上流で実行承認待ちの場合は、個人Forkでの実行と区別して記録します。

## 実機

2026-10-24の利用者によるDuo実機テストは分離前のビルド6に対するものです。今回の分離後ビルドを実機で再テストしたとは記載しません。実機操作は利用者が担当します。

## 分離後のローカル確認（2026-10-25）

- Xcode 27.1 / iOS 27.1 SDK：アプリ本体とキーボード拡張のSimulator向けビルドが成功。
- iPhone 18 Pro / iOS 27.0：選択した回帰テスト35件、UIテスト2件が成功。
- Duo / iOS 27.1：見開きと閉じた横画面を操作し、[比較画像](iphone-duo-screenshots.md)を保存。
- SwiftLint：エラー0件、既存警告54件。actionlint、シェル構文、プロジェクト・スキーム形式、git diff --check成功。
