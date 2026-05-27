# pylsp plugin

Registers `python-lsp-server` (pylsp) as Claude's Python LSP, with the `pylsp-mypy` plugin enabled so mypy diagnostics flow through the LSP. Jedi-backed go-to-def / references / hover / symbols come along for the ride.

## Requirements

`pylsp` and `pylsp-mypy` available somewhere the wrapper can find them:

1. `$VIRTUAL_ENV/bin/` (an activated venv), or
2. on PATH, or
3. `<project>/.venv/bin/` walking up from cwd, or
4. `~/.venv/bin/`

Install once into your preferred venv:

```sh
~/.venv/bin/pip install 'python-lsp-server[all]' pylsp-mypy
```

## What it does

- **`.lsp.json`** points at `${CLAUDE_PLUGIN_ROOT}/bin/pylsp`, which resolves `pylsp` at runtime (`$VIRTUAL_ENV` → PATH → walk-up project `.venv/bin` → `~/.venv/bin`; the PATH step skips plugin wrappers via a marker). Initialization options enable `pylsp_mypy` in `live_mode` and disable the built-in linters, since ruff handles linting/formatting (`ruff-lsp` or the `/ruff-fix` command).
- **Opt-in fallback hook** — *off by default.* Set `PYLSP_MYPY_ON_EDIT=1` to run `mypy` on each edited file via `bin/mypy`. Redundant once pylsp is active (pylsp-mypy already streams the same diagnostics), so it exists only as an escape hatch for a harness that ignores the plugin-supplied `.lsp.json`.

## Notes

- If you'd rather have ruff run inside pylsp too, install `python-lsp-ruff` and add `"ruff": { "enabled": true }` under `pylsp.plugins` — but `ruff server` (the `ruff-lsp` plugin) is faster.

## Install

```sh
claude --plugin-dir ~/Development/claude/pylsp
```
