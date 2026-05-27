---
description: Fix shell scripts with shuck (changed files by default, or paths you pass)
argument-hint: "[path ...]"
---
Run the shuck fixer, then act on what's left.

Run exactly this (it passes any arguments straight through):

!`"$CLAUDE_PLUGIN_ROOT/bin/shuck-fix" $ARGUMENTS`

That runs `shuck check --fix` on the target shell files — the repo's changed +
untracked `.sh`/`.bash`/`.zsh`/`.ksh` files (plus shebang-detected scripts) when
no paths are given, or the paths in `$ARGUMENTS` if provided — then prints any
diagnostics shuck could not auto-fix.

If there are remaining diagnostics: fix the ones whose correction is
unambiguous, and for anything requiring a judgement call, list it for the user
rather than guessing. If there were none, just confirm the files are clean.
