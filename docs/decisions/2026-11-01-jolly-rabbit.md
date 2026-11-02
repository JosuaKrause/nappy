# jolly-rabbit — Records and pieces of work are named, not numbered · 2026-11-01

The player's decision (inbox #937 in plaid-penguin, inbox #941): the point of the name system is to not use numbers, so a further
record of an entry is named and so is every piece of an entry's work. This changes the per-entry files and the `--entry` numbering
that M223 set up (`2026-09-26-M223.md`), where a second record took `-2`, `-3` and on.

**Built.** `tools/new-name.sh decision --entry <entry>` and `review --entry <entry>` write `<entry>.md` while that is free, and
otherwise `<entry>-<adjective>-<animal>.md`, a pair no name in `docs/todo`, `docs/decisions`, `docs/review` and `docs/playtests`
uses. The pair is drawn like any other, so two branches building at once draw two different names and nothing is renumbered.
Everything that recognises an entry's records accepts the named form beside the numbered one: the queue's wait check in
`tools/queue.sh` (an `after:` naming an entry whose only record is a named one is over), CI's `tools/ci_queue_update.py` (a deleted
item needs a record for its entry), the name lint in `tools/lint.sh`, and the review-list text in `tools/lib_queue.py`.
`tools/check_citations.py` and `tools/decisions.sh` read a record by its file name, so a named record is cited by its whole name
(`<entry words>-<adjective>-<animal>`) and found as any other. Records already numbered, among them the minty-quail refactor's
`-2` to `-50`, keep their names and keep working.

**The rules.** `committing`, `playtest-feedback`, `orchestrating`, `using-tools`, `docs/DECISIONS.md`, `docs/TODO.md` and
`docs/REVIEW.md` say a further record is named and a piece of an entry's work, whether an item file or the label a brief, a PR title
or a record title gives a part of a step, is named, never numbered or lettered ("part B3", "slice 4", "2a/4").

**Read as:** "numbers already assigned stay" (inbox #941) is permanent: the existing numbered records, the refactor's `-2` to `-50`
and the open pull requests' `-46` to `-50` among them, keep their names and are not renamed once the refactor ends (PLAYTEST-144 6
says the same for numbered files). The context the player said yes to on #941 had said the refactor's numbered records would be
renamed after it ends; this is the builder's reading, open to the player's overturn.

**Rejected.** Leaving `--entry` as it was and numbering with a number-aware script; the player declined a fix that keeps numbers.
