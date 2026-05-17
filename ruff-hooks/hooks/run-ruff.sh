#!/usr/bin/env bash
# PostToolUse hook: runs ruff check --fix and ruff format on edited Python files.
# Delegates ruff resolution to the bin/ruff wrapper so PATH / per-project venv /
# ~/.venv fallback all work the same way as the LSP entry.

set -u

payload="$(cat)"
file="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')"

[[ -z "$file" ]] && exit 0
[[ "$file" != *.py && "$file" != *.ipynb ]] && exit 0
[[ ! -f "$file" ]] && exit 0

ruff_bin="${CLAUDE_PLUGIN_ROOT}/bin/ruff"

"$ruff_bin" check --fix --quiet "$file" 2>&1 || true
"$ruff_bin" format --quiet "$file" 2>&1 || true

# Opt-out: set RUFF_HOOK_NO_DIAGNOSTICS=1 if an LSP (ruff-lsp or pylsp+pylsp_ruff)
# already surfaces ruff diagnostics — the hook step would just duplicate them.
if [[ -z "${RUFF_HOOK_NO_DIAGNOSTICS:-}" ]]; then
  if ! remaining="$("$ruff_bin" check --no-fix --output-format=concise "$file" 2>&1)"; then
    echo "ruff diagnostics for $file:" >&2
    echo "$remaining" >&2
  fi
fi

exit 0
