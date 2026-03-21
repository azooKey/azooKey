#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CI_MODE=false
SKIP_LINT=false

for arg in "$@"; do
  case "$arg" in
    --ci)
      CI_MODE=true
      ;;
    --skip-lint)
      SKIP_LINT=true
      ;;
    -h|--help)
      cat <<'USAGE'
Usage: scripts/bootstrap.sh [--ci] [--skip-lint]

Options:
  --ci         Enable CI mode (strict checks + metadata validation)
  --skip-lint  Skip SwiftLint availability checks
USAGE
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

cd "$ROOT_DIR"

echo "[1/5] Syncing git submodules"
git submodule sync --recursive
git submodule update --init --recursive

echo "[2/5] Checking required developer tools"
if ! command -v git >/dev/null 2>&1; then
  echo "git was not found. Install git first." >&2
  exit 1
fi
if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild was not found. Install Xcode first." >&2
  exit 1
fi
if ! command -v swift >/dev/null 2>&1; then
  echo "swift command was not found. Install Xcode command line tools." >&2
  exit 1
fi
if [ ! -f "azooKey.xcodeproj/project.pbxproj" ]; then
  echo "azooKey.xcodeproj was not found. Run this script from repository root." >&2
  exit 1
fi

echo "[3/5] Running AzooKeyCore package build checks"
swift build --package-path AzooKeyCore --target SwiftUIUtils
swift build --package-path AzooKeyCore --target KeyboardThemes

echo "[4/5] Validating SwiftLint setup"
if [ "$SKIP_LINT" = true ]; then
  echo "Skipped (requested by --skip-lint)"
else
  if command -v swiftlint >/dev/null 2>&1; then
    swiftlint --version
  else
    if [ "$CI_MODE" = true ]; then
      echo "SwiftLint is required in CI mode but was not found." >&2
      exit 1
    fi
    cat <<'NOTICE'
SwiftLint is not installed.
Install with:
  brew install swiftlint
NOTICE
  fi
fi

echo "[5/5] Running CI-only checks"
if [ "$CI_MODE" = true ]; then
  swift package dump-package --package-path AzooKeyCore >/dev/null
  xcodebuild -list -project azooKey.xcodeproj >/dev/null
else
  echo "Skipped (local mode)"
fi

echo "Bootstrap completed successfully."
