# ruff-lsp

Registers `ruff server` as the Python LSP. Use this when you want ruff to be your *only* Python language server — diagnostics, code actions (autofix, organize imports), and formatting via LSP.

## Mutually exclusive with `pylsp`

Both `ruff-lsp` and `pylsp` claim `python` as their LSP language. The harness only routes a given language to one server, so enabling both is undefined behavior in practice — pick one:

| Want…                                | Enable                      |
|:-------------------------------------|:----------------------------|
| Ruff only (lint + format, no types)  | `ruff-lsp` + `ruff-hooks`   |
| Ruff + mypy (via pylsp + pylsp-mypy) | `pylsp` + `ruff-hooks`      |

## How ruff is resolved

Ships its own thin wrapper at `bin/ruff`:

1. `command -v ruff` on PATH (skips itself to avoid recursion)
2. Walks up from `$PWD` looking for `.venv/bin/ruff`
3. Falls back to `~/.venv/bin/ruff`
4. Exits 127 with a stderr note if not found

This is the same wrapper as `ruff-hooks`; both plugins ship their own copy so each repo is self-contained.

## Pairs with `ruff-hooks`

The LSP gives you diagnostics and code actions, but it doesn't autofix or format on every edit by itself. Enable `ruff-hooks` alongside this plugin so post-edit autofix + format still happen deterministically. Set `RUFF_HOOK_NO_DIAGNOSTICS=1` in your shell to suppress the hook's diagnostic-emit step (the LSP already surfaces them).

## Requirements

- `ruff` discoverable per the resolution rules above
- ruff ≥ 0.4.0 (when `ruff server` shipped as stable)

## Install

Via the [georgeharker marketplace](../.claude-plugin/marketplace.json):

```sh
claude plugin marketplace add ~/Development/claude
claude plugin install ruff-lsp@georgeharker
```
