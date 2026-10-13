#!/bin/bash
# Zotero の PDF フォルダを WebDAV と双方向同期する。
# 設定は ~/.config/zotero-pdf-sync/config から読む（REMOTE, REMOTE_DIR, LOCAL_DIR）。
# 初回のみ: sync.sh --resync（実体がある側の端末で実行すること）
set -euo pipefail

CONF="${ZOTERO_PDF_SYNC_CONF:-$HOME/.config/zotero-pdf-sync/config}"
# shellcheck disable=SC1090
source "$CONF"
: "${REMOTE:?}" "${REMOTE_DIR:?}" "${LOCAL_DIR:?}"

RCLONE="$(command -v rclone || echo /opt/homebrew/bin/rclone)"
mkdir -p "$LOCAL_DIR"

extra=()
[[ "${1:-}" == "--resync" ]] && extra+=(--resync)
[[ "${1:-}" == "--dry-run" ]] && extra+=(--dry-run)

exec "$RCLONE" bisync "$LOCAL_DIR" "${REMOTE}:${REMOTE_DIR}" \
  --create-empty-src-dirs \
  --conflict-resolve newer \
  --max-delete 25 \
  --exclude ".DS_Store" \
  --exclude "*.tmp" \
  --exclude ".~lock.*" \
  --resilient --recover \
  -v "${extra[@]}"
