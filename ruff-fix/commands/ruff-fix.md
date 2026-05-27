---
description: Fix and format Python with ruff (changed files by default, or paths you pass)
argument-hint: "[path ...]"
---
Run the ruff fixer, then act on what's left.

Run exactly this (it passes any arguments straight through):

!`"$CLAUDE_PLUGIN_ROOT/bin/ruff-fix" $ARGUMENTS`

That runs `ruff check --fix` and `ruff format` on the target Python files — the
repo's changed + untracked files when no paths are given, or the paths in
`$ARGUMENTS` if provided — then prints any diagnostics ruff could not auto-fix.

If there are remaining diagnostics: fix the ones whose correction is
unambiguous, and for anything requiring a judgement call, list it for the user
rather than guessing. If there were none, just confirm the files are clean.
