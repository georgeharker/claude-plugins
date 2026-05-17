#!/usr/bin/env bash
# Fallback hook: runs mypy on edited Python files. Redundant once pylsp's
# pylsp-mypy plugin is active in the editor, but harmless and useful as a
# safety net if the harness ignores plugin-supplied .lsp.json.
# Delegates mypy resolution to bin/mypy.

set -u

payload="$(cat)"
file="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty')"

[[ -z "$file" ]] && exit 0
[[ "$file" != *.py && "$file" != *.pyi ]] && exit 0
[[ ! -f "$file" ]] && exit 0

mypy_bin="${CLAUDE_PLUGIN_ROOT}/bin/mypy"

out="$("$mypy_bin" --follow-imports=silent --show-error-codes --no-color-output --no-error-summary "$file" 2>&1)"
status=$?

if [[ $status -ne 0 && -n "$out" ]]; then
  echo "mypy errors in $file:" >&2
  echo "$out" >&2
fi

exit 0
