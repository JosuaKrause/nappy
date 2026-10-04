# olive-tapir — The inbox appends a further word to a captured note · 2026-10-03 · not from an entry


*(The player, 2026-10-03: "don't create new inbox notes for the same topic -- keep adding comments to it" · "make this part of the skill" · "well, only if you already know that there is an open issue about this topic -- don't spend time reading all issues just to figure out whether there is an overlap")*

**A further word on the topic of an open captured note is appended to that note, never captured as
a new one, and only when the agent already knows the note.** One session captured five notes in a
row on one topic (inbox #504 to #508, filed in [quiet-yak](../playtests/2026-10-03-quiet-yak.md)), a line each. `tools/inbox.py append N --body-file F
[--context-file C]` posts the player's further words on a captured note as a comment under the same
identity rules as `capture`; the inbox skill says to use it only for a note the agent captured or
read this session, and never to read or search the inbox for an overlap, otherwise to capture.
`append` refuses a note that is not captured (a note the player wrote gets the player's own
comments), a closed note, a missing or unusable role and empty text.

**The marker-comment trust rule is the builder's mechanism, not something the player chose, and is
open to overturn.** The player agreed that a captured note is marked by the script ("Yes, marked by
the script") and that "Only the player's own comments are the player's words"; nothing said how
appended words are told from an agent's question. The mechanism: the comment's first line is an HTML
comment, `APPEND_MARKER`, which only `append` writes, and it counts as the player's words only when a
capture identity (`nappy-claude-orchestrator[bot]` or `nappy-codex-coder[bot]`) wrote it on a note a
capture identity opened with the `captured` label. The same comment on a note the player opened, from
anybody else, or from the player is not read as appended words. This narrows the skill's "Only the
player's own comments are the player's words" for captured notes: there, the player's own comments
and these marked comments are. `show` prints them as the player's, and `close --pr` and
`tools/ci_transcription.py` require them word for word in the filing's playtest file like the body.
`ask`, `capture --context-file` and `append` refuse text with a marker line, so nothing the script
writes as a question can be promoted to the player's words. Context goes in the same comment as the
words, above a second marker line (`WORDS_MARKER`), so a failed post can neither leave the context
alone on the issue nor duplicate it on a retry; the context is the agent's side and is not required
in the playtest file.

**This supersedes** [leafy-finch-3](2026-09-27-leafy-finch-3.md)'s open item, "CI's transcription
check still reading only a note's body, while `close` also checks the player's comments": CI now
reads the appended comments on a captured note too. It does not read the player's own comments,
which `close` still does. CI is looser than `close` on where the words are: CI accepts the body and
each appended comment in any playtest file the PR adds, while `close` needs them all in one file.

**Alternatives not taken:** a label on the comment (a comment cannot carry a label); a separate
note per further word (what the player asked not to do); reading the player's own comments only,
which an agent cannot write as the player; a visible prefix in the comment text (it would show on
the issue and be copied into a playtest by hand).

**Open to overturn:** the marker mechanism and its trust rule; one comment holding the context and
the words rather than two; CI looser than `close`; `append` refusing a note the player wrote.
