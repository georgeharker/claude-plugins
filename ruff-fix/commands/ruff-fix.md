---
description: Fix and format Python with ruff (changed files by default, or paths you pass)
argument-hint: "[path ...]"
---
Run the ruff fixer, then act on what's left.

Run exactly this (it passes any arguments straight through; the fallback covers
invocations where the harness left CLAUDE_PLUGIN_ROOT unset — e.g. programmatic
Skill-tool calls — by finding the newest installed copy in the plugin cache):

!`fixer="${CLAUDE_PLUGIN_ROOT:-}/bin/ruff-fix"; [ -x "$fixer" ] || fixer="$(find "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/cache" -type f -path "*/ruff-fix/*/bin/ruff-fix" 2>/dev/null | sort | tail -n1)"; if [ -x "$fixer" ]; then "$fixer" $ARGUMENTS; else echo "ruff-fix: helper not found — CLAUDE_PLUGIN_ROOT is unset and no installed copy exists under plugins/cache; fall back to running ruff directly."; fi`

That runs `ruff check --fix` and `ruff format` on the target Python files — the
repo's changed + untracked files when no paths are given, or the paths in
`$ARGUMENTS` if provided — then prints any diagnostics ruff could not auto-fix.

If there are remaining diagnostics: fix the ones whose correction is
unambiguous, and for anything requiring a judgement call, list it for the user
rather than guessing. If there were none, just confirm the files are clean.
