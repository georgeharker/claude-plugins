#!/usr/bin/env bash
# Opt-in fallback hook: run mypy on edited Python files.
#
# OFF by default. pylsp's bundled pylsp-mypy plugin already provides mypy
# diagnostics through the LSP (see .lsp.json), so this is redundant in the
# normal setup. It exists only as an escape hatch for a harness that ignores
# the plugin-supplied .lsp.json. Set PYLSP_MYPY_ON_EDIT=1 to enable it.
# Delegates mypy resolution to bin/mypy.

set -u

[[ -z "${PYLSP_MYPY_ON_EDIT:-}" ]] && exit 0

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
