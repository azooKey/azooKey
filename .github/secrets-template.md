# GitHub Secrets Template

`upload-build.yml` を利用する際に必要な GitHub Actions Secrets の一覧です。

## Required Secrets

- `EXPORT_OPTIONS`
  - `ExportOptions.plist` の内容（文字列）を保存
- `APPLE_API_KEY`
  - App Store Connect API key (`.p8`) を **base64** 化した文字列
- `APPLE_API_KEY_ID`
  - App Store Connect API Key ID
- `APPLE_API_ISSUER_ID`
  - App Store Connect Issuer ID
- `APPLE_ID`
  - アップロードに使うApple ID
- `APP_SPECIFIC_PASSWORD`
  - Apple IDのApp専用パスワード

## Security Rules

- 実値はリポジトリへコミットしない
- ローカルに保存する場合は `.env.local` などGit管理外ファイルを使う
- APIキーや証明書は定期的にローテーションする
