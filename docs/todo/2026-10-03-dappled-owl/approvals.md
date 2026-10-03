**Only a reviewer identity approves a pull request** ([busy-ibis](../../playtests/2026-10-03-busy-ibis.md),
statement 9: "we can prevent approvals from non-reviewers").

Claude Code has two identities that open pull requests, `claude-coder` and `claude-orchestrator`,
and each can approve the other's: GitHub stops only a PR's own author. That approval counts toward
the one approving review `main` requires. The guard lets both forms through today:
`run claude-orchestrator -- gh pr review 5 --approve`, and a `.../reviews` POST with
`event=APPROVE`.

The guard denies an approving review unless the command is wrapped as a reviewer
(`claude-reviewer`, `codex-reviewer`), the mirror of its rule that a reviewer may not push; a
COMMENT or REQUEST_CHANGES review stays allowed to any identity. Tests for both forms under each
role, and **committing** says only a reviewer identity approves.
