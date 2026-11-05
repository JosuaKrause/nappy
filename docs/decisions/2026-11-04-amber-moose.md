# amber-moose — The orchestrating session holds a standing permission to merge · 2026-11-04 · not from an entry

The player asked for "a standing permission to merge PRs when you're the orchestrator", because
"otherwise I have to give permission manually for every new orchestrator session" and with it they
can "just say" the session is the orchestrator and to continue (inbox #1063).

**What it was.** Merging a pull request, enabling auto-merge and delegating a merge required the
player's explicit permission in the current session, and a permission given in another session did
not carry over (the record 2026-09-12, "PR merges require permission in the current session").
Every new orchestrator session therefore began by asking the player for a permission the player
had already given the one before.

**What it is now.** The orchestrating Claude Code session holds the player's standing permission to
merge, in `CLAUDE.md`, once **committing**'s merge gates hold: a ready review against the head or a
delta review of what came after, and green CI. Enabling auto-merge and handing a merge to an agent
or monitor are merging and are covered. The per-session rule is overturned for that session only,
by the player. **committing**, **orchestrating**, **session-cleanup**, **merging-main**,
**pr-review** and the comment in the write guard hook say the same.

**What still holds.** Every other session (an implementation or review agent, a Codex session)
merges nothing without the player's word in that session. A release still needs its own explicit
go-ahead in the session, and the restart prompt still never records one (polite-marten). The
write guard still denies a direct merge command, since a merge goes through a wrapped identity.

**Open to overturn:** whether Claude Code's auto-mode classifier lets the merge command through on
the strength of `CLAUDE.md` alone; the repository cannot change that.
