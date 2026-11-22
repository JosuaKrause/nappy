# polite-otter — Questions about an inbox note go on the board, not on its issue · 2026-11-22

**What it was.** Every question to the player went on the Nappy board, apart from one about an inbox
note, which could be asked on the note's issue with `tools/inbox.py ask` (dotted-quail 1). Whether
that exception stayed was asked on the board as notes-questions-where, and both rules stood until the
player answered it.

**What changed.** The player's answer is that the progression is board, then inbox, then repository:
questions and answers happen on the board, new notes can come to the board too, the player may still
open an issue directly on GitHub, and a follow-up question about one goes to the board
(inbox #1639 in gentle-penguin). `CLAUDE.md`'s line for asking the player a question, the **board**
skill and the **inbox** skill (with its filing steps) now send every question there, naming the note
it is about, and capture the player's answer on the board into the note.

**What was not taken.** Keeping the issue as a second place for a question about a note was the
exception the answer removes; the orchestrator's pick on the board was board only, and the player answered
the question with the board as where questions and answers live, and said they will primarily use it.

**What stays.** The `ask` subcommand of `tools/inbox.py` and its test in `tools/test_rules_hooks.sh`
are untouched, since a change to the tool is code and outside this change; no rule sends a question
through it any more.
