# claude plugins

Personal Claude Code plugins that wrap tools the official LSP plugins don't cover. Split into small, composable pieces so you can mix-and-match LSP, fix commands, and (opt-in) post-edit behavior.

## Plugins

| Plugin                          | Type                  | What it does                                                                                          |
|:--------------------------------|:----------------------|:------------------------------------------------------------------------------------------------------|
| [ruff-fix](./ruff-fix)          | command (+ opt-in hook)| `/ruff-fix` — `ruff check --fix` + `ruff format` on changed/named Python files, then report the rest  |
| [ruff-lsp](./ruff-lsp)          | LSP                   | Register `ruff server` as the Python LSP (diagnostics + code actions)                                 |
| [pylsp](./pylsp)                | LSP (+ opt-in hook)   | Register `python-lsp-server` + `pylsp-mypy` as the Python LSP; opt-in mypy-on-edit fallback hook       |
| [shuck](./shuck)                | LSP + command (+ opt-in hook)| Register `shuck server` as the shell LSP; `/shuck-fix` lint+autofix `.sh`/`.bash`/`.zsh`         |

## How they work

The design mirrors a stock LSP editor: **diagnostics stream automatically, fixes are explicit.**

1. **LSP (`ruff-lsp`, `pylsp`, `shuck`)** — a `.lsp.json` registers a language server. The harness is the LSP client: it owns `didOpen`/`didChange`/`didClose` and surfaces `publishDiagnostics` to Claude after edits. You don't (and a hook can't) send edit notifications yourself — that's the harness's job.
2. **Fix commands (`/ruff-fix`, `/shuck-fix`)** — an *explicit* action you (or Claude, via the skill/command) invoke to run `--fix` + format on the changed files (or paths you pass) and report what couldn't be auto-fixed. Unlike a `didChange`, this is the only thing that mutates files, and only when invoked — nothing rewrites a file behind Claude's back mid-edit.
3. **Opt-in PostToolUse hooks** — off by default. For anyone who wants the old automatic format-on-edit, each plugin's hook can be switched on with an env var (below). Off-by-default means the default behavior is identical to having no hook, but it's one variable away.

### Opt-in hook switches (all default off)

| Env var | Effect |
|:--------|:-------|
| `RUFF_FIX_ON_EDIT=1`         | On Python edit: autofix + format the file, then report remaining diagnostics |
| `RUFF_DIAGNOSTICS_ON_EDIT=1` | On Python edit: report ruff diagnostics only (no mutation)                   |
| `SHUCK_FIX_ON_EDIT=1`        | On shell edit: autofix the file, then report remaining diagnostics           |
| `SHUCK_DIAGNOSTICS_ON_EDIT=1`| On shell edit: report shuck diagnostics only (no mutation)                   |
| `PYLSP_MYPY_ON_EDIT=1`       | On Python edit: run a fallback mypy check (for harnesses that ignore `.lsp.json`) |

If you run an LSP, you generally want the diagnostics switches **off** — the LSP already streams those, and the hook would just duplicate them. The fix switches are additive (an LSP does not auto-mutate files).

### Tool resolution

The `ruff`, `pylsp`, `mypy`, and `shuck` wrappers in each plugin's `bin/` resolve the underlying tool at runtime, preferring the most explicit signal of intent. Both the `.lsp.json` and the commands/hooks invoke the wrapper, so resolution is consistent and survives the harness running with a stripped PATH.

Python tools (`ruff`, `pylsp`, `mypy`):

1. `$VIRTUAL_ENV/bin/<tool>` if set — an activated venv, which survives a stripped PATH
2. `<tool>` on PATH — respects activation, pyenv/conda shims, and global installs
3. `.venv/bin/<tool>` walking up from cwd — a project venv on disk but not active
4. `~/.venv/bin/<tool>` — personal global fallback

`shuck` (a Rust tool, no venv analog): `shuck` on PATH → `target/{release,debug}/shuck` walking up from cwd → `~/.cargo/bin/shuck`.

## Setup matrix

The Python plugins compose, but **`ruff-lsp` and `pylsp` are mutually exclusive** — both claim `python` as their LSP and the harness only routes a language to one server.

| Want                                                  | Enable                      | Skip                |
|:------------------------------------------------------|:----------------------------|:--------------------|
| Ruff + mypy types via pylsp (recommended)             | `pylsp` + `ruff-fix`        | `ruff-lsp`          |
| Ruff diagnostics in-editor (lint+format), no mypy     | `ruff-lsp` + `ruff-fix`     | `pylsp`             |
| Just a fix command, no LSP                            | `ruff-fix`                  | `ruff-lsp`, `pylsp` |

In the recommended combo, `pylsp` streams mypy + jedi diagnostics live via the LSP, and `/ruff-fix` handles ruff lint/format/fix on demand. (`pylsp` ships `pylsp_ruff` disabled in its `.lsp.json`, so ruff diagnostics come from `ruff-lsp` or from running `/ruff-fix`, not from pylsp.)

## Install (persistent, via the local marketplace)

This directory ships its own marketplace manifest at [.claude-plugin/marketplace.json](.claude-plugin/marketplace.json) (id: `georgeharker`). Register it as a local marketplace and install the combo you want — no git remote required:

```sh
claude plugin marketplace add ~/Development/claude
# Recommended combo (ruff + mypy via pylsp):
claude plugin install ruff-fix@georgeharker
claude plugin install pylsp@georgeharker
claude plugin install shuck@georgeharker
```

To pull in plugin edits without bumping versions: `claude plugin marketplace update georgeharker`. To uninstall: `claude plugin uninstall <name>`.

## Install (per-session, ad-hoc)

```sh
claude --plugin-dir ~/Development/claude/ruff-fix \
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
  { "source": { "source": "git", "repo": "georgeharker/ruff-fix" } }
  ```
  Trade-off: cleaner ownership per plugin, but versioning is now spread across N repos and consumers see N entries.

For one user with three closely related plugins, monorepo is simpler. Switch to per-plugin repos only if you want independent release cadence or community contributions on one plugin without the others.

## Requirements

- `jq` on PATH (the opt-in hooks parse the tool payload with it)
- `git` (the fix commands default to the repo's changed + untracked files)
- `ruff` — via `$VIRTUAL_ENV`, on PATH, in any `.venv/bin/` walking up from cwd, or in `~/.venv/bin/`
- `python-lsp-server` + `pylsp-mypy` — same resolution; commonly in a project `.venv` or `~/.venv/`
- `mypy` — same resolution (only needed if you opt into `PYLSP_MYPY_ON_EDIT`)
- `shuck` — on PATH, in a local `target/{release,debug}/`, or in `~/.cargo/bin/` (`cargo install shuck`)

If a tool isn't found, the wrapper prints a one-line note to stderr and exits non-zero; the commands and opt-in hooks degrade gracefully rather than blocking your edit.
