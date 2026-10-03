priority: now

# dappled-owl — The write guard sees through aliases, and only a reviewer approves · filed 2026-10-03

> "let's do A for aliases. env was chosen because it's set by the session and not directly. but
> even with tricks like updating the settings all it will do is prompt the command to me anyway.
> we can prevent approvals from non-reviewers."

[busy-ibis](../../playtests/2026-10-03-busy-ibis.md), statements 6 to 9 and 13. The after-the-fact
reviews of #448 ([review](https://github.com/JosuaKrause/nappy/pull/448#pullrequestreview-5400326104),
the write guard asks where no identity can work) and #424
([review](https://github.com/JosuaKrause/nappy/pull/424#pullrequestreview-5400340003), the
`claude-orchestrator` identity) found gaps in `.claude/hooks/github-write-guard.sh`, the hook that
denies a GitHub write outside an agent identity (the tall-egret and frosty-pelican records). The
player chose a fix for each, in one PR: `aliases.md`, `approvals.md`, `switch-wording.md`. The
review's two smaller points are `read-false-denies.md`.

#448's first finding, a tag push whose refspec comes through `xargs` being asked about rather than
denied, is PR #453's own work and not repeated here.

**This entry is built after PRs #429 and #453 merge**, since both rewrite the same hook; one PR,
whose tests go in `tools/test_rules_hooks.sh`, and which checks whether the Codex adapter
`tools/codex-hooks.py` and `tools/test_codex_hooks.py` need to change (`CLAUDE.md`, "Codex
integration"). The player: "guard follow up PR can be merged whenever it's ready" (statement 13).

**Proposed, not asked for:** the band `now`, the filer's reading of statement 13.
