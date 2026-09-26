## M57 — The docs cannot go stale · `feature/the-docs-cannot-go-stale`

Asked for on 2026-09-01 (playtest 18, findings 1–3): *"can we enforce that documentation is written
in a way that it cannot easily become stale? for example we don't need to state how many tests are
green in the claude docs"*, *"there should be no quest logs outside of decisions.md"*, and the
approvals *"drift guard sounds good. stats.sh sounds good."* The rules already existed in
`CLAUDE.md`; this milestone built the machinery, because a rule somebody has to remember is not a
rule. Built same-day, four commits:

- **`tools/lint.sh`** — flags, in the governed docs (everything but `DECISIONS.md`, the playtests
  and `evidence/README.md`), the five sentence shapes that go stale on their own: a backticked
  commit hash, a branch name, a check count, a ticked box, a status word after `·` in a heading.
  `lint-allow` in an HTML comment suppresses a deliberate hit. Tuned against the real tree until
  its output was only true positives — `CLAUDE.md`'s self-referential forbidden-style examples and
  `TODO.md`'s milestone identifiers and dated player quotes must not fire it.
- **A `PostToolUse` hook** (`.claude/hooks/lint-docs.sh`) runs the linter on a governed doc the
  moment it is edited and surfaces hits in the same turn — enforcement at the sentence, not at the
  commit. PostToolUse cannot block, so the committing skill carries the stop: a lint hit before a
  commit is a stop.
- **The drift guard**, session-cleanup step: if `tuning.gd` or `event_catalogue.gd` changed this
  session, grep the governed docs for what moved — the number re-audit found all of its drift
  around retuned constants whose doc sentences stood still.
- First run over the tree: **zero hits** — the linter's shapes and the re-audit's findings turned
  out disjoint (wrong figures and stale narration in prose are a different staleness than hashes
  and status markers), which is why both exist.
