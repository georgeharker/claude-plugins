# pylsp plugin

Registers `python-lsp-server` (pylsp) as Claude's Python LSP, with the `pylsp-mypy` plugin enabled so mypy diagnostics flow through LSP rather than a one-shot hook. Jedi-backed go-to-def / references / hover / symbols come along for the ride.

## Requirements

`pylsp` and `pylsp-mypy` available somewhere the wrapper can find them:

1. on PATH, or
2. in `<project>/.venv/bin/` walking up from cwd, or
3. in `~/.venv/bin/`

Install once into your preferred venv:

```sh
~/.venv/bin/pip install 'python-lsp-server[all]' pylsp-mypy
```

## What it does

- **`.lsp.json`** points at `${CLAUDE_PLUGIN_ROOT}/bin/pylsp` (the wrapper in this plugin's `bin/` dir), which resolves `pylsp` at runtime: PATH → walk-up project `.venv/bin/pylsp` → `~/.venv/bin/pylsp`. Initialization options enable `pylsp_mypy` in `live_mode` and disable the built-in linters since the `ruff` plugin handles linting/formatting.
- **Fallback hook** (`PostToolUse` on Edit/Write/MultiEdit) runs `mypy` on the edited file via the same kind of wrapper at `bin/mypy`. Redundant once pylsp is active in the session, but useful insurance if plugin-supplied `.lsp.json` is currently a no-op in Claude Code.

## Notes

- If you'd rather have ruff run inside pylsp too, install `python-lsp-ruff` and add `"ruff": { "enabled": true }` under `pylsp.plugins` — but `ruff server` (the separate `ruff` plugin) is faster.

## Install

```sh
claude --plugin-dir ~/Development/claude/pylsp
```
