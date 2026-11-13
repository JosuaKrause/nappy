# Playtest amber-goose — A bug fix for inbox.py cite, and bugs get the highest priority

2026-11-13.

## #1442

1. **Context** (the assistant's):

   Said in the orchestrating session of 2026-11-13, answering this paragraph of the orchestrator's report on the Fable review of #1441 (DawnContext):

   > **A tool bug the reviewer ran into.** `tools/inbox.py cite` edits files when run as a lookup, and it doubles a citation that wraps across a line. The reviewer undid its accidental edit. This is the same bug behind your two uncommitted record edits in the main checkout; the fix for those is still `git checkout --` on the two files.

   The reviewer's own words on it: it ran `uv run python tools/inbox.py cite 1432` expecting a lookup and it changed `.claude/skills/orchestrating/SKILL.md`; and "`inbox.py cite` doubles a citation that wraps across a line break ("inbox #1432 in" / "minty-rabbit" became "in minty-rabbit in")". An earlier session's `tools/inbox.py cite 1159` rewrote "inbox #1159 and #1156" in `docs/decisions/2026-10-18-minty-quail-quiet-swan.md` and `-tall-lynx.md` the same way.

2. **The note.**

   > schedule a bug fix. remember those get highest priority

3. **Read as:** (the assistant's interpretation, not the player's words)

   The bug to fix is `tools/inbox.py cite`: it writes files when an agent runs it to look a citation up, and it doubles a citation that wraps across a line break. The band is `bug`, which the player named. "Those get highest priority" is read as a standing rule: an entry in the `bug` band is started, reviewed and merged ahead of all other work, an entry the player has put first included (today the orchestrating skill lets only work on how the project is worked on pass that fence).
