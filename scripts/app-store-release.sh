#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

PROJECT_PATH="${APP_STORE_PROJECT:-${REPO_ROOT}/azooKey.xcodeproj}"
SCHEME="${APP_STORE_SCHEME:-MainApp}"
CONFIGURATION="${APP_STORE_CONFIGURATION:-Release}"
TEAM_ID="${APP_STORE_TEAM_ID:-9S3UXHYP65}"
OUTPUT_ROOT="${APP_STORE_OUTPUT_DIR:-${REPO_ROOT}/build/app-store}"
BUILD_NUMBER="${BUILD_NUMBER:-}"
MARKETING_VERSION="${MARKETING_VERSION:-}"

ASC_KEY_PATH="${ASC_KEY_PATH:-}"
ASC_KEY_ID="${ASC_KEY_ID:-}"
ASC_ISSUER_ID="${ASC_ISSUER_ID:-}"

ACTION="archive-and-upload"
UPLOAD_ARCHIVE_PATH=""
REQUIRE_CLEAN="NO"
DRY_RUN="NO"
MANAGE_BUILD_NUMBER="NO"

usage() {
    cat <<'USAGE'
App Store Connect向けのArchive作成とアップロードを自動化します。

使い方:
  scripts/app-store-release.sh [オプション]

主なオプション:
  --archive-only                 Archiveだけを作成する
  --upload-only PATH             既存の.xcarchiveをアップロードする
  --build-number NUMBER          CURRENT_PROJECT_VERSIONを一時的に上書きする
  --marketing-version VERSION    MARKETING_VERSIONを一時的に上書きする
  --team-id TEAM_ID              Developer Team IDを上書きする
  --output-dir DIR               成果物を保存する親ディレクトリ
  --require-clean                Gitに未コミット変更があれば中止する
  --manage-build-number          アップロード時のビルド番号管理をXcodeに任せる
  --dry-run                      xcodebuildを実行せずコマンドだけ表示する
  -h, --help                     このヘルプを表示する

App Store Connect APIキーを使う場合:
  ASC_KEY_PATH      .p8秘密鍵のパス
  ASC_KEY_ID        Key ID
  ASC_ISSUER_ID     Issuer ID

APIキーを指定しない場合は、Xcodeに登録済みのAppleアカウントを使います。

例:
  BUILD_NUMBER=42 scripts/app-store-release.sh
  scripts/app-store-release.sh --archive-only --build-number 42
  scripts/app-store-release.sh --upload-only build/MyApp.xcarchive
USAGE
}

log() {
    printf '[app-store] %s\n' "$*"
}

warn() {
    printf '[app-store] WARNING: %s\n' "$*" >&2
}

fail() {
    printf '[app-store] ERROR: %s\n' "$*" >&2
    exit 1
}

require_value() {
    local option="$1"
    local value="${2:-}"
    [[ -n "${value}" ]] || fail "${option} には値が必要です"
}

make_absolute() {
    local path="$1"
    if [[ "${path}" == /* ]]; then
        printf '%s\n' "${path}"
    else
        printf '%s\n' "${REPO_ROOT}/${path}"
    fi
}

print_command() {
    local argument
    printf '  '
    for argument in "$@"; do
        printf '%q ' "${argument}"
    done
    printf '\n'
}

run_logged() {
    local log_path="$1"
    shift

    if [[ "${DRY_RUN}" == "YES" ]]; then
        print_command "$@"
        return
    fi

    "$@" 2>&1 | tee "${log_path}"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --archive-only)
            [[ "${ACTION}" == "archive-and-upload" ]] || fail "実行モードは1つだけ指定してください"
            ACTION="archive-only"
            shift
            ;;
        --upload-only)
            [[ "${ACTION}" == "archive-and-upload" ]] || fail "実行モードは1つだけ指定してください"
            require_value "$1" "${2:-}"
            ACTION="upload-only"
            UPLOAD_ARCHIVE_PATH="$2"
            shift 2
            ;;
        --build-number)
            require_value "$1" "${2:-}"
            BUILD_NUMBER="$2"
            shift 2
            ;;
        --marketing-version)
            require_value "$1" "${2:-}"
            MARKETING_VERSION="$2"
            shift 2
            ;;
        --team-id)
            require_value "$1" "${2:-}"
            TEAM_ID="$2"
            shift 2
            ;;
        --output-dir)
            require_value "$1" "${2:-}"
            OUTPUT_ROOT="$2"
            shift 2
            ;;
        --require-clean)
            REQUIRE_CLEAN="YES"
            shift
            ;;
        --manage-build-number)
            MANAGE_BUILD_NUMBER="YES"
            shift
            ;;
        --dry-run)
            DRY_RUN="YES"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            fail "不明なオプションです: $1"
            ;;
    esac
done

PROJECT_PATH="$(make_absolute "${PROJECT_PATH}")"
OUTPUT_ROOT="$(make_absolute "${OUTPUT_ROOT}")"

[[ -d "${PROJECT_PATH}" ]] || fail "Xcodeプロジェクトが見つかりません: ${PROJECT_PATH}"
[[ -f "${PROJECT_PATH}/xcshareddata/xcschemes/${SCHEME}.xcscheme" ]] \
    || fail "共有スキームが見つかりません: ${SCHEME}"
[[ -n "${TEAM_ID}" ]] || fail "Developer Team IDが空です"

command -v /usr/bin/xcodebuild >/dev/null 2>&1 || fail "xcodebuildが見つかりません"
command -v /usr/bin/plutil >/dev/null 2>&1 || fail "plutilが見つかりません"
command -v tee >/dev/null 2>&1 || fail "teeが見つかりません"

if [[ -n "${BUILD_NUMBER}" && ! "${BUILD_NUMBER}" =~ ^[0-9]+([.][0-9]+){0,2}$ ]]; then
    fail "ビルド番号は数字、またはピリオドで区切った数字を指定してください: ${BUILD_NUMBER}"
fi

if [[ -n "${MARKETING_VERSION}" && ! "${MARKETING_VERSION}" =~ ^[0-9]+([.][0-9]+){0,2}$ ]]; then
    fail "マーケティングバージョンは数字、またはピリオドで区切った数字を指定してください: ${MARKETING_VERSION}"
fi

AUTHENTICATION_ARGS=(-allowProvisioningUpdates)
USES_API_KEY="NO"
if [[ -n "${ASC_KEY_PATH}${ASC_KEY_ID}${ASC_ISSUER_ID}" ]]; then
    [[ -n "${ASC_KEY_PATH}" && -n "${ASC_KEY_ID}" && -n "${ASC_ISSUER_ID}" ]] \
        || fail "APIキー認証にはASC_KEY_PATH、ASC_KEY_ID、ASC_ISSUER_IDのすべてが必要です"
    ASC_KEY_PATH="$(make_absolute "${ASC_KEY_PATH}")"
    [[ -f "${ASC_KEY_PATH}" ]] || fail "API秘密鍵が見つかりません: ${ASC_KEY_PATH}"
    AUTHENTICATION_ARGS+=(
        -authenticationKeyPath "${ASC_KEY_PATH}"
        -authenticationKeyID "${ASC_KEY_ID}"
        -authenticationKeyIssuerID "${ASC_ISSUER_ID}"
    )
    USES_API_KEY="YES"
fi

if command -v git >/dev/null 2>&1 && git -C "${REPO_ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    GIT_COMMIT="$(git -C "${REPO_ROOT}" rev-parse --short HEAD)"
    if [[ -n "$(git -C "${REPO_ROOT}" status --porcelain)" ]]; then
        if [[ "${REQUIRE_CLEAN}" == "YES" ]]; then
            fail "Gitに未コミット変更があります（--require-cleanが指定されています）"
        fi
        warn "Gitに未コミット変更があります。この状態のソースをArchiveします"
    fi
    log "Git commit: ${GIT_COMMIT}"
fi

RUN_ID="$(date '+%Y%m%d-%H%M%S')-$$"
RUN_DIR="${OUTPUT_ROOT}/${RUN_ID}"
DERIVED_DATA_PATH="${RUN_DIR}/DerivedData"
ARCHIVE_PATH="${RUN_DIR}/azooKey.xcarchive"
EXPORT_PATH="${RUN_DIR}/upload"
EXPORT_OPTIONS_PATH="${RUN_DIR}/ExportOptions.plist"

mkdir -p "${RUN_DIR}"

if [[ "${ACTION}" == "upload-only" ]]; then
    UPLOAD_ARCHIVE_PATH="$(make_absolute "${UPLOAD_ARCHIVE_PATH}")"
    [[ -d "${UPLOAD_ARCHIVE_PATH}" ]] || fail "Archiveが見つかりません: ${UPLOAD_ARCHIVE_PATH}"
    ARCHIVE_PATH="${UPLOAD_ARCHIVE_PATH}"
fi

log "Mode: ${ACTION}"
log "Project: ${PROJECT_PATH}"
log "Scheme: ${SCHEME} (${CONFIGURATION})"
log "Team: ${TEAM_ID}"
log "Archive: ${ARCHIVE_PATH}"
if [[ -n "${BUILD_NUMBER}" ]]; then
    log "Build number override: ${BUILD_NUMBER}"
fi
if [[ -n "${MARKETING_VERSION}" ]]; then
    log "Marketing version override: ${MARKETING_VERSION}"
fi
if [[ "${USES_API_KEY}" == "YES" ]]; then
    log "Authentication: App Store Connect API key (${ASC_KEY_ID})"
else
    log "Authentication: Xcode account"
fi

if [[ "${ACTION}" != "upload-only" ]]; then
    ARCHIVE_COMMAND=(
        /usr/bin/xcodebuild
        -project "${PROJECT_PATH}"
        -scheme "${SCHEME}"
        -configuration "${CONFIGURATION}"
        -destination "generic/platform=iOS"
        -derivedDataPath "${DERIVED_DATA_PATH}"
        -archivePath "${ARCHIVE_PATH}"
        -hideShellScriptEnvironment
    )
    ARCHIVE_COMMAND+=("${AUTHENTICATION_ARGS[@]}")
    ARCHIVE_COMMAND+=("DEVELOPMENT_TEAM=${TEAM_ID}")

    if [[ -n "${BUILD_NUMBER}" ]]; then
        ARCHIVE_COMMAND+=("CURRENT_PROJECT_VERSION=${BUILD_NUMBER}")
    fi
    if [[ -n "${MARKETING_VERSION}" ]]; then
        ARCHIVE_COMMAND+=("MARKETING_VERSION=${MARKETING_VERSION}")
    fi

    ARCHIVE_COMMAND+=(clean archive)

    log "Archiveを作成します"
    run_logged "${RUN_DIR}/archive.log" "${ARCHIVE_COMMAND[@]}"
    if [[ "${DRY_RUN}" != "YES" ]]; then
        log "Archiveを作成しました: ${ARCHIVE_PATH}"
    fi
fi

if [[ "${DRY_RUN}" != "YES" ]]; then
    [[ -f "${ARCHIVE_PATH}/Info.plist" ]] || fail "Archiveが不正です: ${ARCHIVE_PATH}"

    ARCHIVED_VERSION="$(/usr/bin/plutil -extract ApplicationProperties.CFBundleShortVersionString raw \
        -o - "${ARCHIVE_PATH}/Info.plist" 2>/dev/null || true)"
    ARCHIVED_BUILD="$(/usr/bin/plutil -extract ApplicationProperties.CFBundleVersion raw \
        -o - "${ARCHIVE_PATH}/Info.plist" 2>/dev/null || true)"
    if [[ -n "${ARCHIVED_VERSION}" && -n "${ARCHIVED_BUILD}" ]]; then
        log "Archived version: ${ARCHIVED_VERSION} (${ARCHIVED_BUILD})"
    fi
fi

if [[ "${ACTION}" == "archive-only" ]]; then
    if [[ "${DRY_RUN}" == "YES" ]]; then
        log "ドライランが完了しました"
    else
        log "完了しました。ログ: ${RUN_DIR}/archive.log"
    fi
    exit 0
fi

/usr/bin/plutil -create xml1 "${EXPORT_OPTIONS_PATH}"
/usr/bin/plutil -insert method -string app-store-connect "${EXPORT_OPTIONS_PATH}"
/usr/bin/plutil -insert destination -string upload "${EXPORT_OPTIONS_PATH}"
/usr/bin/plutil -insert signingStyle -string automatic "${EXPORT_OPTIONS_PATH}"
/usr/bin/plutil -insert teamID -string "${TEAM_ID}" "${EXPORT_OPTIONS_PATH}"
/usr/bin/plutil -insert uploadSymbols -bool YES "${EXPORT_OPTIONS_PATH}"
/usr/bin/plutil -insert manageAppVersionAndBuildNumber -bool "${MANAGE_BUILD_NUMBER}" "${EXPORT_OPTIONS_PATH}"

UPLOAD_COMMAND=(
    /usr/bin/xcodebuild
    -exportArchive
    -archivePath "${ARCHIVE_PATH}"
    -exportPath "${EXPORT_PATH}"
    -exportOptionsPlist "${EXPORT_OPTIONS_PATH}"
)
UPLOAD_COMMAND+=("${AUTHENTICATION_ARGS[@]}")

log "App Store Connectへアップロードします"
run_logged "${RUN_DIR}/upload.log" "${UPLOAD_COMMAND[@]}"

if [[ "${DRY_RUN}" == "YES" ]]; then
    log "ドライランが完了しました"
else
    log "アップロードが完了しました"
    log "成果物とログ: ${RUN_DIR}"
fi
