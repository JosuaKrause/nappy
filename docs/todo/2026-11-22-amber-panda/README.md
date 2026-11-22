priority: later

# amber-panda — Retire tools/inbox.py ask · filed 2026-11-22

No player's words name this; it follows [#1640](https://github.com/JosuaKrause/nappy/pull/1640) (questions about an inbox note go on the board, inbox #1639 in gentle-penguin).

**Found.** No rule asks through `tools/inbox.py ask` now: the inbox skill says so ("No rule asks through `tools/inbox.py ask` now") and the using-tools catalogue marks it unused.

**What holds today.** The subcommand stays until this entry is built because #1640 (polite-otter, `tools/decisions.sh polite-otter`: questions about an inbox note go on the board, not on its issue) left it in place, unused. Every place that mentions `ask` (`rg -n "\bask\b" .claude/hooks tools/inbox.py .claude/skills`):

- `.claude/hooks/github-write-guard.sh`: the comment at the list of the tool's subcommands (the line naming `capture`, `append`, `correct`, `ask`, `close --pr`, `reopen --pr`) and the denial message that lists `capture, append, correct, ask, close --pr, reopen --pr`.
- `.claude/skills/inbox/SKILL.md`: the sentence on the tool's mark lines that tells them from "a question asked with `ask`", the list "`ask`, `capture`, ..." after it, and "No rule asks through `tools/inbox.py ask` now".
- `.claude/skills/using-tools/SKILL.md`: the `tools/inbox.py` row's `ask` (unused) item.
- `tools/inbox.py`: the module docstring (opening line and the `ask N` usage line), the mark-lines sentence, the comment "told from an `ask` question", the usage example, the parser's `metavar`, the `ask` subparser and its dispatch.
- `tools/test_inbox.py` (its `ask` cases) and `tools/test_rules_hooks.sh` (the write guard's "tools/inbox.py ask ... -> allow" case).

**What the fix must hold.** All of the above are changed together: the subcommand, its parser entry and help, the docstring and comments, the guard's comment and denial message, both tests, the using-tools item and the inbox skill's sentences; a repeat of the `rg` above shows no mention left. `tools/pycheck.sh` and `tools/test_rules_hooks.sh` pass.

*Proposed, not asked for:* the band `later`.
