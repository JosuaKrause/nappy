priority: later
after: 2026-10-18-minty-quail

# amber-ibis — What the rules review found outside the rule files: three rules no test holds, two suites that do not exist, and small tool gaps · filed 2026-11-09

**Where this comes from.** The player had every rule file reviewed and reworked ("have another
fable agent review all skills/claude/rule files", "let's do all the suggested changes for the
hooks/skills/claudes etc", inbox #1267). The rework made the skills true against the code; while
matching each rule to the suite that holds it, its builders and reviewers found things outside the
rule files that the rework could not fix. They are filed here so they are not lost.

*Not asked for:* none of these items is the player's request. Each is a defect the rework found
and named, filed by the orchestrator; the band `later` and the wait for the refactor (many of them
are comments and docs in files the refactor is rewriting) are the filer's proposal.

**It speaks of the skills as the rework leaves them.** Where an item says a skill no longer cites
a suite, or says a rule is unenforced, or names the record sandy-alpaca, that is the state once the
rework's four pull requests have merged (the game's domain skills, the process skills, the
orchestration skills, and the hooks with `CLAUDE.md`).

**Items:** `lethal-field-across-a-day.md`, `closures-through-the-planner.md`,
`no-pelican-png.md`, `suites-that-do-not-exist.md`, `small-false-sentences.md`,
`citation-after-a-comma.md`, `tool-help-gaps.md`, `old-briefs.md`.
