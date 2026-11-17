# downy-sparrow — Fable writes only the design of every piece of Fable work (inbox #1501, #1504 in silky-lemur) · 2026-11-17 · not from an entry

**What the rule said before.** Fable designed the code of what the player named as Fable's, and
reviewed what it had designed. On a queue entry carrying `fable-only: true` (every pull request
building one of its items carries the `fable-only` label), Fable designed the code and reviewed it,
and the Fable designer also decided whether the coding was too complex to hand off: it wrote the
code itself if so, and otherwise handed it to the lowest model that could do it, a brief never
deciding this for it (inbox #1293 in grassy-trout, inbox #1299 in grassy-trout, inbox #1432 in
minty-rabbit). Outside the label, the model table's review row sent the review of anything Fable
designed to Fable, the player's own third rule on Fable, confirmed as permanent (inbox #1299 in
grassy-trout statement 9, and its confirmation, inbox #1303 in grassy-trout). The designer's report
said whether it wrote the code or handed it off, and the orchestrator briefed the lowest model able
on a hand-off (inbox #1436 in tiny-squirrel).

**The player's words**, on two inbox notes.

Inbox #1501 in silky-lemur, three statements:

1. "let's change the fable only label to let opus do the review"
2. "also fable is only allowed to write down the design -- no implementation and no review -- it needs
   to provide enough context for both in its design"
3. "that means it cannot decide to do those things by itself either" (read as: those things are
   implementing and reviewing).

Inbox #1504 in silky-lemur, the answer to the board question `fable-outside-the-label`, which asked whether
statement 2 holds for every design Fable writes or only for work under the `fable-only` label:
"every fable work item".

**Asked for and overturned.** Asked for X · overturned to Y on 2026-11-17, because Z:

- Asked for: "and we can do a third rule that if fable designed something fable needs to review"
  (inbox #1299 in grassy-trout statement 9, confirmed as permanent in inbox #1303 in grassy-trout) ·
  overturned to: Fable never reviews, and Opus reviews every Fable design, under the `fable-only`
  label or not, on 2026-11-17, because the player answered the board question
  `fable-outside-the-label` with "every fable work item" (inbox #1504 in silky-lemur), after
  inbox #1501 in silky-lemur had said "let's change the fable only label to let opus do the review".
  Nothing is left of the older rule.

**What the rule says now.** In every piece of work Fable takes part in, labelled `fable-only` or
not, Fable's part is the written design alone. It never writes the code and never reviews it, and it
cannot decide to take either up itself, not even for a part it judges too complex to hand off: no
exception remains. The design carries enough context for both the builder and the reviewer. The
orchestrator picks the builder's model, the lowest that can do it from the design, as the model
table says for any build; Opus reviews every Fable design. What the `fable-only` label still does
is mark the work the player named as Fable's to design, and `tools/ci_fable_only.py` still checks
that a pull request building such an entry carries it; its check is unchanged, since it only reads
the label.

**Where it is written.** `docs/TODO.md` ("`fable-only: true` says that an entry's work is the
player's choice of Fable's to design"), the model table and its opening paragraph in the
orchestrating skill, the queue-entry bullet in the playtest-feedback skill, the reviewer sentence
under "Briefing a review agent" in the pr-review skill, the docstring of `tools/ci_fable_only.py`,
the comment above its step in `.github/workflows/ci.yml`, and the polite-tapir entry's README.
