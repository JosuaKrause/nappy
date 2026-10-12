priority: next
after: 2026-10-03-dappled-owl

# plush-raven — The git-grep guard fails closed and passes no long text as an argument · filed 2026-10-12

Found while fixing #736 (dappled-owl, the write guard sees through aliases, and only a reviewer
approves), not reported by the player. CI on Linux showed the write guard allowing two 64 KB
commands: it passed more than 128 KB to `jq` as one argument, which Linux refuses and macOS does not,
and a hook that prints nothing lets the command through. #736 fixed the write guard (the
[dappled-owl record](../../decisions/2026-10-03-dappled-owl.md), "The guard fails closed").

`.claude/hooks/git-grep-guard.sh`, the hook that denies an unbounded `git grep`, has the same two
patterns: it exits, which allows, when `jq` is missing, and it passes its 14 KB jq program as an
argument. Make it fail closed the way the write guard now does, and pass long text through a file
or stdin, with tests that shim `jq` to refuse an argument over 128 KB and force each failure; check
whether the Codex adapter `tools/codex-hooks.py` needs the same (CLAUDE.md, "Codex integration").

*Proposed, not asked for:* the band `next`, and waiting on dappled-owl, whose fix it copies.
