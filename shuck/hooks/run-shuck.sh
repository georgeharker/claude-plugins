#!/usr/bin/env bash
# PostToolUse hook: runs `shuck check --fix` on shell files Claude edits,
# then reports remaining diagnostics to stderr so Claude sees them.

set -u

payload="$(cat)"
file="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty')"

[[ -z "$file" ]] && exit 0
[[ ! -f "$file" ]] && exit 0

case "$file" in
  *.sh|*.bash|*.zsh|*.ksh|*.mksh|*.dash) ;;
  *)
    # Also handle extensionless shell scripts via shebang sniffing.
    first_line="$(head -n1 "$file" 2>/dev/null || true)"
    case "$first_line" in
      '#!'*sh) ;;
      *) exit 0 ;;
    esac
    ;;
esac

# Delegate shuck resolution to the bin/shuck wrapper so the LSP entry and
# this hook share the same cargo / project-build / ~/.cargo/bin lookup.
shuck_bin="${CLAUDE_PLUGIN_ROOT}/bin/shuck"

if ! "$shuck_bin" --version >/dev/null 2>&1; then
  echo "shuck plugin: shuck not found (try: cargo install shuck)" >&2
  exit 0
fi

"$shuck_bin" check --fix --output-format=concise "$file" >/dev/null 2>&1 || true

remaining="$("$shuck_bin" check --output-format=concise "$file" 2>&1 || true)"
if [[ -n "$remaining" ]]; then
  echo "shuck diagnostics for $file:" >&2
  echo "$remaining" >&2
fi

exit 0
