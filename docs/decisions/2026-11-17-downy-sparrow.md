# downy-sparrow — Fable writes only the design of fable-only work · 2026-11-17 · not from an entry

**What the rule said before.** On a queue entry carrying `fable-only: true` (every pull request
building one of its items carries the `fable-only` label), Fable designed the code and reviewed it.
The Fable designer also decided whether the coding was too complex to hand off: it wrote the code
itself if so, and otherwise handed it to the lowest model that could do it, a brief never deciding
this for it (inbox #1293 in grassy-trout, inbox #1299 in grassy-trout, inbox #1432 in minty-rabbit).
The model table's review row sent the review of anything Fable designed to Fable. The designer's
report said whether it wrote the code or handed it off, and the orchestrator briefed the lowest
model able on a hand-off (inbox #1436 in tiny-squirrel).

**The player's words**, three statements on one inbox note (inbox #1501):

1. "let's change the fable only label to let opus do the review"
2. "also fable is only allowed to write down the design -- no implementation and no review -- it needs
   to provide enough context for both in its design"
3. "that means it cannot decide to do those things by itself either" (read as: those things are
   implementing and reviewing).

**What the rule says now.** On a `fable-only` entry Fable's part is the written design alone. It
never writes the code and never reviews it, and it cannot decide to take either up itself, not even
for a part it judges too complex to hand off: no exception remains. The design carries enough
context for both the builder and the reviewer. The orchestrator picks the builder's model, the
lowest that can do it from the design, as the model table says for any build; Opus reviews. The
rule holds for every `fable-only` entry from now on. `tools/ci_fable_only.py`'s check is unchanged,
since it only reads the label.

**Where it is written.** `docs/TODO.md` ("`fable-only: true` says that Fable writes only the design
of an entry's work"), the model table and its opening paragraph in the orchestrating skill, the
queue-entry bullet in the playtest-feedback skill, the docstring of `tools/ci_fable_only.py`, and
the polite-tapir entry's README.
