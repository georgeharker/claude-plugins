# claude plugins

Personal Claude Code plugins that wrap tools the official LSP plugins don't cover. Split into small, composable pieces so you can mix-and-match LSP and post-edit behavior.

## Plugins

| Plugin                          | Type        | What it does                                                                                  |
|:--------------------------------|:------------|:----------------------------------------------------------------------------------------------|
| [ruff-hooks](./ruff-hooks)      | hook        | Autofix + format Python on every edit; surface remaining ruff diagnostics on stderr           |
| [ruff-lsp](./ruff-lsp)          | LSP         | Register `ruff server` as the Python LSP                                                      |
| [pylsp](./pylsp)                | LSP + hook  | Register `python-lsp-server` + `pylsp-mypy` as the Python LSP; mypy-on-edit fallback hook     |
| [shuck](./shuck)                | LSP + hook  | Lint + autofix `.sh`/`.bash`/`.zsh` on every edit; register `shuck server` LSP                |

## Setup matrix

The Python plugins compose, but **`ruff-lsp` and `pylsp` are mutually exclusive** — both claim `python` as their LSP and the harness only routes a language to one server.

| Want                                          | Enable                              | Skip                |
|:----------------------------------------------|:------------------------------------|:--------------------|
| Ruff only — lint + format, no type-checking   | `ruff-hooks` + `ruff-lsp`           | `pylsp`             |
| Ruff + mypy types via pylsp (recommended)     | `ruff-hooks` + `pylsp`              | `ruff-lsp`          |
| Just autofix-on-edit, no LSP                  | `ruff-hooks`                        | `ruff-lsp`, `pylsp` |
| Ruff LSP only, no autofix-on-edit             | `ruff-lsp`                          | `ruff-hooks`        |

If you enable an LSP that surfaces ruff diagnostics (either `ruff-lsp`, or `pylsp` with its bundled `pylsp_ruff` plugin enabled), set `RUFF_HOOK_NO_DIAGNOSTICS=1` in your shell so `ruff-hooks` skips its diagnostic-emit step. The autofix + format steps still run; only the duplicate diagnostic pass is suppressed.

## How they work

Each plugin ships one or both of:

1. A `PostToolUse` hook that fires after `Edit` / `Write` / `MultiEdit` / `NotebookEdit` — reads the edited file path from the tool payload, runs the relevant tool, and emits any remaining diagnostics on stderr so Claude can iterate.
2. A `.lsp.json` registering an LSP server for the relevant language.

The `ruff-hooks`, `ruff-lsp`, and `pylsp` plugins each ship a thin wrapper in `bin/` that resolves the underlying tool at runtime:

- prefer `command -v <tool>` on PATH (with a self-recursion guard)
- else walk up from cwd looking for `.venv/bin/<tool>` (per-project venv)
- else `~/.venv/bin/<tool>` (global venv fallback)

Both the `.lsp.json` and the hooks invoke the wrapper, so resolution is consistent and survives the harness running with a stripped PATH.

## Install (persistent, via the local marketplace)

This directory ships its own marketplace manifest at [.claude-plugin/marketplace.json](.claude-plugin/marketplace.json) (id: `georgeharker`). Register it as a local marketplace and install the combo you want — no git remote required:

```sh
claude plugin marketplace add ~/Development/claude
# Recommended combo (ruff + mypy via pylsp):
claude plugin install ruff-hooks@georgeharker
claude plugin install pylsp@georgeharker
claude plugin install shuck@georgeharker
```

To pull in plugin edits without bumping versions: `claude plugin marketplace update georgeharker`. To uninstall: `claude plugin uninstall <name>`.

## Install (per-session, ad-hoc)

```sh
claude --plugin-dir ~/Development/claude/ruff-hooks \
       --plugin-dir ~/Development/claude/pylsp \
       --plugin-dir ~/Development/claude/shuck
```

## Going public

Each plugin dir is self-contained (own `.claude-plugin/plugin.json`, own `bin/` wrappers where needed) so each can become its own git repo. Two layouts work:

- **Monorepo**: keep this top-level directory as one repo. The marketplace manifest with relative `./<dir>` sources works identically when added from a local path or a GitHub URL.
  ```sh
  cd ~/Development/claude && git init && git remote add origin <url> && git push -u origin main
  # consumers: claude plugin marketplace add georgeharker/claude-plugins
  ```
- **Per-plugin repos**: split each plugin into its own repo, then keep a separate marketplace repo whose `marketplace.json` uses git URLs instead of relative paths:
  ```json
  { "source": { "source": "git", "repo": "georgeharker/ruff-hooks" } }
  ```
  Trade-off: cleaner ownership per plugin, but versioning is now spread across N repos and consumers see N entries.

For one user with three closely related plugins, monorepo is simpler. Switch to per-plugin repos only if you want independent release cadence or community contributions on one plugin without the others.

## Requirements

- `jq` on PATH (hooks parse the payload with it)
- `ruff` — on PATH, in any `.venv/bin/` walking up from cwd, or in `~/.venv/bin/`
- `python-lsp-server` + `pylsp-mypy` — same resolution as above; commonly in `~/.venv/`
- `mypy` — same resolution as above
- `shuck` — on PATH (`cargo install shuck`)

If a tool isn't found, the hook prints a one-line note to stderr and exits 0 — it won't block your edit.
