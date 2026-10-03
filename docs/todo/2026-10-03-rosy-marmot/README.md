priority: later

# rosy-marmot — The write guard's question shows the command · filed 2026-10-03

> "it was some command -- the hook doesn't tell me what the command itself is"

[minty-hedgehog](../../playtests/2026-10-03-minty-hedgehog.md), statement 15 (note #459). **When the write guard asks the player about a write, the question
shows the command.** With asking switched on (`NAPPY_ASK_FOR_PLAYER_WRITES=1`), the reason
`.claude/hooks/github-write-guard.sh` gives is built from `$flagged`, the kind of write it found
(`git push`), not the command, so the player cannot tell which push, to where, or whether it pushes
anything; the comment above that branch says the mobile app "shows only the command", which is not
what the player saw. The frosty-pelican record makes the same claim and stays as history; the hook's
comment is what changes.

**Asked:** whether the note's Fix section is the player's ask or an agent's draft the player posted:
"Include the command itself in `permissionDecisionReason`, cut to a readable length (about the first
200 characters, with an ellipsis when cut)", "Correct the comment's claim about what the mobile app
shows", "Add a test in `tools/test_rules_hooks.sh`", and check the Codex adapter. Until answered they
are the filer's proposal. PR #429 edits the same comment block; this is built after it, with the
other guard work in dappled-owl.
