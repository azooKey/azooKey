# App Store ConnectへのArchive・アップロード

`scripts/app-store-release.sh` は、`MainApp` のRelease Archiveを作成し、App Store Connectへアップロードします。

このスクリプトが行うのはバイナリのアップロードまでです。App Store Connect上でのメタデータ入力、ビルドの選択、審査への提出、リリース操作は行いません。

## 事前準備

- `MainApp` スキームがArchiveできるXcodeを使用する
- Apple Distribution証明書と自動署名を利用できる状態にする
- Xcodeの Settings > Accounts で、Team `9S3UXHYP65` を利用できるAppleアカウントにログインする
- App Store Connect上で使用していないビルド番号を決める

## 実行

リポジトリのルートで、次のように実行します。

```bash
BUILD_NUMBER=42 scripts/app-store-release.sh
```

以下が順番に実行されます。

1. `MainApp` / `Release` をiOS向けにArchive
2. App Store配布用に自動署名
3. dSYMを含めてApp Store Connectへアップロード

Archive、ExportOptions、ログは `build/app-store/<日時>-<プロセスID>/` に保存されます。このディレクトリはGitの管理対象外です。

プロジェクトに設定されたビルド番号をそのまま使う場合は、引数なしでも実行できます。

```bash
scripts/app-store-release.sh
```

同じマーケティングバージョンへアップロードするビルド番号は、過去に使用した番号と重複しない値にしてください。`--build-number` を使っても、プロジェクトファイル自体は変更されません。

```bash
scripts/app-store-release.sh --build-number 42
```

マーケティングバージョンも一時的に上書きできます。

```bash
scripts/app-store-release.sh \
  --marketing-version 3.1 \
  --build-number 42
```

## Archiveとアップロードを分ける

Archiveだけを作る場合:

```bash
scripts/app-store-release.sh --archive-only --build-number 42
```

失敗したアップロードだけを再実行する場合:

```bash
scripts/app-store-release.sh \
  --upload-only build/app-store/20260720-120000-12345/azooKey.xcarchive
```

実行予定のコマンドだけを確認する場合:

```bash
scripts/app-store-release.sh --dry-run --build-number 42
```

Gitに未コミット変更があるリリースを禁止する場合:

```bash
scripts/app-store-release.sh --require-clean --build-number 42
```

## App Store Connect APIキーを使う

ローカルのXcodeアカウントの代わりに、App Store Connect APIキーで署名管理とアップロードを認証できます。秘密鍵はリポジトリの外に保存し、次の環境変数をすべて指定します。

```bash
export ASC_KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_XXXXXXXXXX.p8"
export ASC_KEY_ID="XXXXXXXXXX"
export ASC_ISSUER_ID="00000000-0000-0000-0000-000000000000"

BUILD_NUMBER=42 scripts/app-store-release.sh
```

`.p8` 秘密鍵はGitへ追加しないでください。

## 設定用の環境変数

| 変数 | 既定値 | 用途 |
| --- | --- | --- |
| `BUILD_NUMBER` | プロジェクト設定 | ビルド番号 |
| `MARKETING_VERSION` | プロジェクト設定 | マーケティングバージョン |
| `APP_STORE_PROJECT` | `azooKey.xcodeproj` | Xcodeプロジェクト |
| `APP_STORE_SCHEME` | `MainApp` | 共有スキーム |
| `APP_STORE_CONFIGURATION` | `Release` | ビルド構成 |
| `APP_STORE_TEAM_ID` | `9S3UXHYP65` | Developer Team ID |
| `APP_STORE_OUTPUT_DIR` | `build/app-store` | 成果物の保存先 |
| `ASC_KEY_PATH` | なし | API秘密鍵のパス |
| `ASC_KEY_ID` | なし | API Key ID |
| `ASC_ISSUER_ID` | なし | API Issuer ID |

すべてのオプションは `scripts/app-store-release.sh --help` で確認できます。
