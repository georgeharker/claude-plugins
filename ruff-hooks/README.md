# ruff-hooks

PostToolUse hook for Python files: autofix lint, format, then emit any remaining diagnostics on stderr so Claude can iterate. No LSP — registers no `.lsp.json`, so it composes cleanly with any Python LSP choice.

## What it does

On every `Edit` / `Write` / `MultiEdit` / `NotebookEdit` against a `.py` or `.ipynb` file:

1. `ruff check --fix --quiet <file>` — autofix every fixable rule in place
2. `ruff format --quiet <file>` — format
3. `ruff check --no-fix --output-format=concise <file>` — emit any remaining (unfixable) diagnostics on stderr

Step 3 is opt-out via `RUFF_HOOK_NO_DIAGNOSTICS=1`. Set this if you've also enabled `ruff-lsp` or `pylsp` with the bundled `pylsp_ruff` plugin — those surface the same diagnostics through the LSP layer, and the hook would just duplicate them.

## How ruff is resolved

The plugin ships a thin wrapper at `bin/ruff` that:

1. Tries `command -v ruff` on PATH (skipping itself to avoid recursion)
2. Walks up from `$PWD` looking for `.venv/bin/ruff` (per-project venv)
3. Falls back to `~/.venv/bin/ruff`
4. Exits 127 with a stderr note if nothing is found

This matches the per-project-venv layout where ruff lives in each project's `.venv/bin/`, not in a global one.

## Pairs with

- **ruff-lsp** — if you want ruff as your Python LSP (diagnostics + code actions). Set `RUFF_HOOK_NO_DIAGNOSTICS=1` to avoid duplicate diagnostics.
- **pylsp** — if you want python-lsp-server (jedi + pylsp-mypy) as your Python LSP. Keep pylsp's bundled `pylsp_ruff` plugin disabled (default) and let ruff-hooks handle ruff; or enable `pylsp_ruff` and set `RUFF_HOOK_NO_DIAGNOSTICS=1`.

You cannot enable **both** ruff-lsp and pylsp — they both claim `python` as their LSP and conflict.

## Requirements

- `ruff` discoverable per the resolution rules above (`uv tool install ruff` works too)
- `jq` on PATH

## Install

Via the [georgeharker marketplace](../.claude-plugin/marketplace.json):

```sh
claude plugin marketplace add ~/Development/claude
claude plugin install ruff-hooks@georgeharker
```
