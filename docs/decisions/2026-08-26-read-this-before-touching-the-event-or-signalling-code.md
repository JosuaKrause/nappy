## Read this before touching the event or signalling code

**The cost table has been regenerated and is now asserted by a test.** `docs/EVENTS.md`, "What
an event actually costs". **Every row moved in M33**, because what changed was the *shape* of
`Tuning.falloff` rather than any one event. One row is now negative — `burnt_shell`, a reminder
rather than an obstacle — where three used to be; `tests/test_events.gd` names exactly that one
as the exemption and requires everything else to cost more to walk through than to walk around,
so a *second* negative event has to be a decision rather than an oversight. The table is only
about events, and since M19 that is no longer the whole cost of a street: a contact with a
pedestrian is ~10.8 points and a car's horn ~8, and neither is in the catalogue. **M27 widened
that gap and M33 narrowed it deliberately** — a balance argument that reaches for the cost table
alone is answering a narrower question than it thinks, but it is a much less narrow one than it
was.

**Running is the wrong move against every event you route *around*, and the right move against
the one kind of thing that follows you.** *(M33.)* `EXCITEMENT_FROM_RUNNING` (14/s) plus the
collapsed decay (3.5/s → 0.5/s) beats the shorter exposure for every row that merely emits, and
`tests/test_events.gd` asserts it **row by row** now. It had only ever been measured and written
into a document, and that is exactly how it broke: M33's change to the falloff shape made running
a point or two cheaper than walking through the four widest fields, silently, in four rows.

The exception is `EventDef.pursues`, and the shape of it is the point. Running cannot be made
correct by moving a constant, because against something that merely emits the two options are the
same outcome at two prices. Against something that **follows** they are opposite outcomes: walking
away loses the day and running away does not. That is why M25's half of this had to be built
rather than tuned, and `Tuning.validate_pursuit()` is the contract — stated over `RUN_SPEED`,
exactly as `TODO.md` said it would have to be.

**No circles, and the replacement has shipped.** *(M22 — this section used to say "has
started".)* The rings are deleted rather than restyled, `EventAuraLayer` is gone, and
`tests/test_danger.gd` asserts it cannot come back, because a comment in a deleted file cannot
stop the next person reaching for a ring when something new needs signalling. Two rules in the
replacement are the whole reason it is better, and both are easy to lose:

- **A cue that marks everything says nothing.** The caret is for danger that *changes over
  time* — telegraphing, lethal, pulsing, swelling — and **not** for whatever is loudest. A
  first pass used "louder than the walking decay", which sounds defensible and marked
  `poster_crew`, `barricade` and `burnt_shell`: the exact three rows the cost table calls
  scenery. That is the ring's own mistake in a new shape, and the test caught it.
- **The mark breathes** with current emission. Without it a pulsing event stops being something
  to time a pass through and becomes something that hurts at random.

The badge announces only what she cannot outwalk, and it **must carry a silhouette** — an arrow
that can only say "something" is an anxiety rather than a warning. Adding to this vocabulary is
a design decision, not a drawing one; read `docs/EVENTS.md`, "The visual vocabulary", first.
