priority: later

# lilac-finch — tools/agent-status.sh reads Claude's transcripts only inside Claude Code · filed 2026-09-26

> "that sounds like a gap in the script" · "that we should fix"

[2026-09-26-curly-quail](../../playtests/2026-09-26-curly-quail.md), statement 6. Run from Terminal
or from Codex, `tools/agent-status.sh` reads Claude Code's agent metadata and transcripts under
`~/.claude/projects/`, which macOS counts as another app's data: it raises the "Terminal.app would
like to access data from other apps" prompt and, denied, finds nothing. Run from Claude Code, the
read comes from Claude Code itself and raises no prompt.
