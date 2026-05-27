# ruff-lsp

Registers `ruff server` as the Python LSP. Use this when you want ruff to be your *only* Python language server — diagnostics, code actions (autofix, organize imports), and formatting via LSP.

## Mutually exclusive with `pylsp`

Both `ruff-lsp` and `pylsp` claim `python` as their LSP language. The harness only routes a given language to one server, so enabling both is undefined behavior in practice — pick one:

| Want…                                | Enable                     |
|:-------------------------------------|:---------------------------|
| Ruff only (lint + format, no types)  | `ruff-lsp` + `ruff-fix`    |
| Ruff + mypy (via pylsp + pylsp-mypy) | `pylsp` + `ruff-fix`       |

## How ruff is resolved

`bin/ruff` resolves the real ruff at runtime, preferring the most explicit signal:

1. `$VIRTUAL_ENV/bin/ruff` if set — an activated venv (survives a stripped PATH)
2. first real ruff on PATH — respects activation, pyenv/conda shims, globals (skips plugin wrappers, which carry a marker, so it never resolves to itself)
3. `.venv/bin/ruff` walking up from `$PWD` — a project venv on disk but not active
4. `~/.venv/bin/ruff` — personal global fallback

This is the same wrapper as `ruff-fix`; both plugins ship their own copy so each repo is self-contained.

## Pairs with `ruff-fix`

The LSP gives you diagnostics and code actions, but the harness does not auto-format or apply fixAll on save. Use the `/ruff-fix` command (from the `ruff-fix` plugin) when you want ruff to fix + format the files you've been editing.

## Requirements

- `ruff` discoverable per the resolution rules above
- ruff ≥ 0.4.0 (when `ruff server` shipped as stable)

## Install

Via the [georgeharker marketplace](../.claude-plugin/marketplace.json):

```sh
claude plugin marketplace add ~/Development/claude
claude plugin install ruff-lsp@georgeharker
```
