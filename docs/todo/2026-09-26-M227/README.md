priority: now

## M227 — Codex works as a sub-agent of a Claude Code session, in a worktree · asked for 2026-09-26

> "let's add a todo to make it possible to use codex as subagent, too" · "from within claude" ·
> "codex subagents should work in worktrees like your subagents" · "not in random tmp folders" ·
> "there might be a claude plugin for using codex? not sure"

[2026-09-26-brisk-heron](../../playtests/2026-09-26-brisk-heron.md), statements 8–10. Codex is installed
here (`codex`, the CLI) and runs non-interactively as `codex exec`; `CLAUDE.md` and the skills are
already shared, and its hooks run through `tools/codex-hooks.py` once the player has approved them
in Codex's `/hooks`, per checkout path.
