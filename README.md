# azooKey

azooKeyはiOS / iPadOS向けの日本語キーボードアプリです。Swiftで実装され、「ニューラルかな漢字変換システム Zenzai」を含む独自開発の高精度変換エンジン、ライブ変換、さらにカスタムキー・カスタムタブなどのユニークなカスタマイズ機能を提供します。

azooKeyは[App Store](https://apps.apple.com/jp/app/azookey-%E8%87%AA%E7%94%B1%E8%87%AA%E5%9C%A8%E3%81%AA%E3%82%AD%E3%83%BC%E3%83%9C%E3%83%BC%E3%83%89%E3%82%A2%E3%83%97%E3%83%AA/id1542709230)で公開しています。

azooKeyの変換エンジンについては[AzooKeyKanaKanjiConverter](https://github.com/azooKey/AzooKeyKanaKanjiConverter)を参照ください。

azooKeyのmacOS版については[azooKey-Desktop](https://github.com/azooKey/azooKey-Desktop)を参照ください。

## コミュニティ＆ベータ版

azooKeyの開発に参加したい方、使い方に質問がある方、要望や不具合報告がある方は、ぜひ[azooKeyのDiscordサーバ](https://discord.gg/dY9gHuyZN5)にご参加ください。

開発中のベータ版は[TestFlight](https://testflight.apple.com/join/x6TKEeB2)で利用できます。フィードバックをDiscordやIssue等でお寄せください。

## 開発ガイド
パフォーマンス改善、バグ修正、機能追加などのPull Requestを歓迎します。機能追加の場合は事前にIssueで議論した方がスムーズです。

開発は基本的に`main`で行います。新規にPRを作成する場合、まずこのレポジトリをフォークし、`main`からブランチを切ってください。

[Let's Contribute](docs/CONTRIBUTING.md)も合わせてお読みください。

### ビルド・利用方法

Apple Developer Account（無料）が必要です。開発環境は最新のXcodeを利用してください。

1. azooKeyを開発環境にクローンします。azooKeyはサブモジュールを利用しているため、`--recursive`オプションを必ず追加してください。

   ```
   git clone https://github.com/azooKey/azooKey --recursive
   cd azooKey
   ```

1. bootstrapスクリプトで初期セットアップを実行します。

   ```
   scripts/bootstrap.sh
   ```

1. `azooKey.xcodeproj`を開き、Xcodeの指示に従って「Run (Command+R)」を実行してください。

1. アプリを開くとキーボードのインストール方法が説明されるので、従ってください。

### テスト方法
[Document](docs/tests.md)をご覧ください。

セットアップの詳細は [docs/setup_local.md](docs/setup_local.md) を参照してください。

### 辞書の変更

azooKeyの辞書ファイルは任意に置き換えることができます。`azooKey_dictionary_storage`を任意のcommitにチェックアウトすることで、過去のバージョンの辞書を利用できます。また、[Google Drive](https://drive.google.com/drive/folders/1Kh7fgMFIzkpg7YwP3GhWTxFkXI-yzT9E?usp=sharing)ではさらに古いバージョンの辞書データも配布しています。

### さらに詳しく

`docs/`内の[Document](./docs/overview.md)をご覧ください。

不明な点は気軽にIssue等でご質問ください。

## 今後のリリース
* 現在、v3.0.1に向けた作業を行っています。

## azooKeyを支援する
GitHub Sponsorsをご利用ください。

## ライセンス
Copyright (c) 2020-2025 Keita Miwa (ensan).

azooKeyはMIT Licenseでライセンスされています。詳しくは[LICENSE](./LICENSE)をご覧ください。
