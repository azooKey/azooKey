#!/bin/bash
# 手元とCIで同じSwiftLintを使っています。
# Xcodeのビルドで自動整形が走らないよう、PATHには追加していません。
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$repo_root"

swiftlint_version=0.65.1
swiftlint_sha256=c1e429b0599cf1b516f369a2d9ec04eaf0e436f3c12b637df8851fa52ff694d0
lint_dir="$(mktemp -d "${TMPDIR:-/tmp}/azookey-swiftlint.XXXXXX")"
trap 'rm -rf "$lint_dir"' EXIT

curl --fail --silent --show-error --location --retry 3 \
  "https://github.com/realm/SwiftLint/releases/download/$swiftlint_version/portable_swiftlint.zip" \
  --output "$lint_dir/swiftlint.zip"
printf '%s  %s\n' "$swiftlint_sha256" "$lint_dir/swiftlint.zip" | shasum -a 256 -c - >&2
ditto -x -k "$lint_dir/swiftlint.zip" "$lint_dir/bin"
chmod +x "$lint_dir/bin/swiftlint"
"$lint_dir/bin/swiftlint" lint --config .swiftlint.yml "$@"
