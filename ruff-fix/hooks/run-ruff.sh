#!/usr/bin/env bash
# Opt-in PostToolUse hook for Python edits. Two independent switches, both OFF
# by default:
#   RUFF_FIX_ON_EDIT=1          autofix + format the edited file (mutates it),
#                               then report anything ruff couldn't fix
#   RUFF_DIAGNOSTICS_ON_EDIT=1  report ruff diagnostics only, no mutation
#
# Default (neither set): nothing runs — diagnostics come from the LSP
# (ruff-lsp / pylsp) and fixes from the explicit `/ruff-fix` command, so no
# file is mutated behind Claude's back during the edit loop. If both are set,
# fix mode wins (it already reports remaining diagnostics).
#
# Shares its implementation with /ruff-fix via bin/ruff-fix.

set -u

fix="${RUFF_FIX_ON_EDIT:-}"
diag="${RUFF_DIAGNOSTICS_ON_EDIT:-}"
[[ -z "$fix" && -z "$diag" ]] && exit 0

payload="$(cat)"
file="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')"

[[ -z "$file" ]] && exit 0
[[ "$file" != *.py && "$file" != *.pyi && "$file" != *.ipynb ]] && exit 0
[[ ! -f "$file" ]] && exit 0

if [[ -n "$fix" ]]; then
  "${CLAUDE_PLUGIN_ROOT}/bin/ruff-fix" "$file" >&2 || true
else
  "${CLAUDE_PLUGIN_ROOT}/bin/ruff-fix" --no-fix "$file" >&2 || true
fi
exit 0
