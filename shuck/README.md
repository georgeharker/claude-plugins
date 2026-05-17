# shuck plugin

Runs `shuck check --fix` on shell files (`.sh`, `.bash`, `.zsh`, `.ksh`, plus extensionless scripts with a shell shebang) after Claude edits them, and reports remaining diagnostics back to Claude.

## Requirements

- `shuck` on PATH (`cargo install shuck`)
- `jq` on PATH

## What it does

- **Hook** (`PostToolUse` on Edit/Write/MultiEdit): autofixes safe issues, then re-runs to surface remaining diagnostics on stderr.
- **`.lsp.json`**: best-effort registration of `shuck server` as a shell LSP. May be a no-op if Claude Code doesn't honor plugin LSP configs yet — the hook is what reliably fires.

## Install

```sh
claude --plugin-dir ~/Development/claude/shuck
```
