#!/usr/bin/env bash
set -euo pipefail
appui_repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
bash "$appui_repo_root/scripts/dev/check-cpu.sh"
cd "$appui_repo_root/example"

# The pinned SDK sometimes starts with an empty workspace preview cache. Prime
# the source through its normal LSP API only after the browser has connected,
# so the reload cannot race initialization of the web runner. No SDK or generated
# source is patched. Node 22 is used only for this local development workaround.
flutter widget-preview start --web-server "$@" 2>&1 |
  while IFS= read -r appui_preview_line; do
    printf '%s\n' "$appui_preview_line"
    if [[ "$appui_preview_line" == *'Done loading previews.'* ]] &&
       rg -Fq 'previews() => [];' .widget_preview/lib/src/generated_preview.dart; then
      if bash "$appui_repo_root/scripts/dev/check-cpu.sh"; then
        node "$appui_repo_root/scripts/dev/prime-previews.mjs" "$PWD"
      fi
    fi
  done
