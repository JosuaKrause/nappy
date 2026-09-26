**It works in a git worktree under `.claude/worktrees/`**, never in a scratch folder
elsewhere. Codex trusts hooks per `hooks.json` path, so a new worktree's hooks need the
player's approval before they run; say how that is handled. The worktree is the fence, not
Codex's sandbox: a `codex exec -s read-only` run still wrote a file through its patch tool.
