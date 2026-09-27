**`tools/agent-status.sh` reads `~/.claude/projects/` only when it runs inside Claude Code** (its
shell sets `CLAUDECODE=1`), and anywhere else skips that part and says why in its output rather
than reaching for another app's data. The rest of its report (branches, uncommitted files, CI,
briefs) is unchanged. A test drives it with and without the variable against a scratch home.
