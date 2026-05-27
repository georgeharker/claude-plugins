#!/usr/bin/env bash
# Opt-in PostToolUse hook for shell edits. Two independent switches, both OFF
# by default:
#   SHUCK_FIX_ON_EDIT=1          autofix the edited file (mutates it), then
#                                report anything shuck couldn't fix
#   SHUCK_DIAGNOSTICS_ON_EDIT=1  report shuck diagnostics only, no mutation
#
# Default (neither set): nothing runs — diagnostics come from the LSP (shuck
# server) and fixes from the explicit `/shuck-fix` command, so no file is
# mutated behind Claude's back during the edit loop. If both are set, fix mode
# wins (it already reports remaining diagnostics).
#
# Shares its implementation with /shuck-fix via bin/shuck-fix.

set -u

fix="${SHUCK_FIX_ON_EDIT:-}"
diag="${SHUCK_DIAGNOSTICS_ON_EDIT:-}"
[[ -z "$fix" && -z "$diag" ]] && exit 0

payload="$(cat)"
file="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty')"

[[ -z "$file" ]] && exit 0
[[ ! -f "$file" ]] && exit 0

if [[ -n "$fix" ]]; then
  "${CLAUDE_PLUGIN_ROOT}/bin/shuck-fix" "$file" >&2 || true
else
  "${CLAUDE_PLUGIN_ROOT}/bin/shuck-fix" --no-fix "$file" >&2 || true
fi
exit 0
