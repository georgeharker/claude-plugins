# shuck plugin

Registers `shuck server` as the shell LSP, and ships a `/shuck-fix` command that runs `shuck check --fix` on shell files (`.sh`, `.bash`, `.zsh`, `.ksh`, plus extensionless scripts with a shell shebang) and reports remaining diagnostics.

## Requirements

- `shuck` on PATH, in a local `target/{release,debug}/`, or in `~/.cargo/bin/` (`cargo install shuck`)
- `git` (the command defaults to the repo's changed files)
- `jq` on PATH (only for the opt-in hook)

## What it does

- **`.lsp.json`** registers `shuck server` as the shell LSP. The harness owns the LSP client, so diagnostics stream to Claude automatically after edits.
- **`/shuck-fix`** — explicit fix command: runs `shuck check --fix` on the repo's changed + untracked shell files (or paths you pass), then reports anything it couldn't auto-fix.
- **Opt-in hook** — *off by default.* Two independent switches: `SHUCK_FIX_ON_EDIT=1` (autofix the edited file) and `SHUCK_DIAGNOSTICS_ON_EDIT=1` (report only, no mutation). With neither set, nothing fires — rely on the LSP for diagnostics and `/shuck-fix` for fixes.

## How shuck is resolved

`bin/shuck` (shuck is a Rust tool, so there's no venv analog):

1. first real shuck on PATH (skips plugin wrappers via a marker)
2. `target/{release,debug}/shuck` walking up from `$PWD` — a local cargo build
3. `~/.cargo/bin/shuck` — cargo's global install dir

## Install

```sh
claude --plugin-dir ~/Development/claude/shuck
```
