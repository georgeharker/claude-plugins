# ruff-fix

A `/ruff-fix` command that runs `ruff check --fix` + `ruff format` on your changed (or named) Python files and reports anything ruff couldn't auto-fix. No LSP — registers no `.lsp.json`, so it composes cleanly with any Python LSP choice. Also ships an opt-in PostToolUse hook for anyone who wants the old automatic-on-edit behavior.

## Why a command (not an automatic hook)

This mirrors stock LSP editor semantics: diagnostics stream automatically from the LSP, and **fixes are an explicit action**. A `PostToolUse` hook that rewrites the just-edited file desyncs Claude's view of it (the next edit can fail to match) and doesn't match how real editors work — `source.fixAll`/format are deliberate actions, not silent mutations on every change. So fixing is a command you (or Claude) invoke.

## `/ruff-fix`

Runs on the repo's changed + untracked Python files by default, or on paths you pass (`/ruff-fix path/to/a.py path/to/b.py`):

1. `ruff check --fix` — autofix every fixable rule in place
2. `ruff format` — format
3. `ruff check --no-fix` — report any remaining (unfixable) diagnostics

## Opt-in hook (off by default)

A `PostToolUse` hook ships disabled. Two independent switches:

| Env var | Effect on each Python edit |
|:--------|:---------------------------|
| `RUFF_FIX_ON_EDIT=1`         | autofix + format the file, then report remaining diagnostics |
| `RUFF_DIAGNOSTICS_ON_EDIT=1` | report ruff diagnostics only (no mutation)                   |

With neither set, nothing fires — rely on the LSP for diagnostics and `/ruff-fix` for fixes. If you run a Python LSP, leave the diagnostics switch off (the LSP already streams those).

## How ruff is resolved

`bin/ruff` resolves the real ruff at runtime, preferring the most explicit signal:

1. `$VIRTUAL_ENV/bin/ruff` if set — an activated venv (survives a stripped PATH)
2. first real ruff on PATH — respects activation, pyenv/conda shims, globals (skips plugin wrappers, which carry a marker, so it never resolves to itself)
3. `.venv/bin/ruff` walking up from `$PWD` — a project venv on disk but not active
4. `~/.venv/bin/ruff` — personal global fallback

## Pairs with

- **ruff-lsp** — ruff as your Python LSP (diagnostics + code actions); `/ruff-fix` for the fix action.
- **pylsp** — python-lsp-server (jedi + pylsp-mypy) as your Python LSP; `/ruff-fix` for ruff lint/format/fix.

You cannot enable **both** ruff-lsp and pylsp — they both claim `python` as their LSP and conflict.

## Requirements

- `ruff` discoverable per the resolution rules above (`uv tool install ruff` works too)
- `git` (the command defaults to the repo's changed files)
- `jq` on PATH (only for the opt-in hook)

## Install

Via the [georgeharker marketplace](../.claude-plugin/marketplace.json):

```sh
claude plugin marketplace add ~/Development/claude
claude plugin install ruff-fix@georgeharker
```
