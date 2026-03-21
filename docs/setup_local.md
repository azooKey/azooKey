# Local Setup Guide

azooKeyのローカル開発環境を最短で準備するためのガイドです。

## 前提条件

- macOS
- 最新のXcode（およびCommand Line Tools）
- `git`
- `Homebrew`（推奨）

## 1. リポジトリをクローン

サブモジュールを利用しているため、`--recursive` を付けてクローンしてください。

```bash
git clone https://github.com/azooKey/azooKey --recursive
cd azooKey
```

既存クローンの場合:

```bash
git submodule sync --recursive
git submodule update --init --recursive
```

## 2. Bootstrapスクリプトを実行

```bash
scripts/bootstrap.sh
```

このスクリプトは以下を実行します。

- サブモジュール同期
- 必須ツール確認（`xcodebuild`, `swift`）
- `AzooKeyCore` の最小ビルド検証
- `swiftlint` の利用可能性チェック
- （`--ci` 指定時）Package/Xcodeプロジェクト定義の整合チェック

CI相当の厳密チェックをローカルで行う場合:

```bash
scripts/bootstrap.sh --ci
```

`swiftlint` チェックのみスキップしたい場合:

```bash
scripts/bootstrap.sh --skip-lint
```

## 3. Xcodeで実行

1. `azooKey.xcodeproj` を開く
2. 任意のターゲットを選択して `Run (⌘R)`

## 4. テスト

- Xcodeから: [docs/tests.md](./tests.md) を参照
- SwiftPM（AzooKeyCore）:

```bash
swift build --package-path AzooKeyCore --target SwiftUIUtils
swift build --package-path AzooKeyCore --target KeyboardThemes
```

## セキュリティ注意

- APIキーや証明書などの機密情報はコミットしないでください。
- CI用シークレット項目は [`.github/secrets-template.md`](../.github/secrets-template.md) を参照してください。
