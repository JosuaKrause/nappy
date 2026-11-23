priority: later

# breezy-yak — minty-quail: stale lines in its entries, reads no item owns, and record nits · filed 2026-11-23

**What this is.** What the minty-quail planner's list gave, each checked against the tree on 2026-11-23: lines
in minty-quail's and polite-tapir's entries that are no longer true, reads of other classes' fields that no item
owns, and nits in three records. A filing from the session's reviews, not from the player's words; the band,
`later`, is the filer's proposal. A builder re-checks each against the tree first, since lines move. Each stale
line is rewritten in the present tense where it stands; each read is given its place in `field-reads.md` or
filed as an entry of its own; the nits are fixed in a docs-only pull request.

**Stale lines.**

- polite-tapir's `README.md`, "Order", the baseline bullet, describes a reading "after the events' field-read
  conversion (row 4b of minty-quail's `event-interface.md`)" as still to take; its `baseline-measurements.md`
  says four readings are built, the fourth after that conversion (the record polite-tapir-crisp-heron). The
  bullet says what the item holds now.
- minty-quail's `field-reads.md` says "Every file under `tests/` is typed but the two that wait for
  polite-tapir's placement step 4". Placement is closed and `rg -l '@warning_ignore_start' tests` finds no
  file; `uv run python tools/check_field_reads.py --summary` counts 4 files with the opt-out line, three under
  `src/` and `tools/split-scenes-crop.gd`. The sentence says every file under `tests/` is typed.
- minty-quail's `typed-everywhere.md`, "Build", says every file under `tests/` "carries no file-level ignore
  but the two below", and nothing below names two; its "Done when" holds for the files under `tests/` (what is
  left of it is the two `PROBE` scripts' strings and the files under `src/`). Both lines say what is true.
- polite-tapir's `README.md` says dawn planning's one read left, "the plan holding its live event", goes with
  row 3b of `event-interface.md`; row 3b is built (its records are listed there). Whether the read is still
  there is the builder's first search, and the sentence is removed or rewritten for what it finds.

**Reads no item owns**, from `tools/field_reads.txt` (the lines are the list's own):

- `Mover.blocked_by` and `Mover.radius`, read in `src/events/event_instance.gd`
  (`Mover.of(_mover.blocked_by & ~Mover.STREETS)`); `field-reads.md` names `Mover` nowhere.
- `ExcitementSource.landed_ever`, read in `src/events/encounter_watch.gd`; `field-reads.md` names the
  excitement source only for its typing.
- `WorldMap.size` and `WorldMap.moves` read in `src/events/` (`plan_builder.gd`, `walk_ground.gd`,
  `dawn_roadblock_count.gd`, `ruled_roadblock_ground.gd`, `event_instance.gd`); `field-reads.md`'s "world map's
  residue" leaves them to "whatever pass gives the blocked tiles an owner of their own", a pass no item names.
- The debug view's suite pass (`tests-one-module.md`: "to move with the debug view's own suite pass"), which no
  item holds a place for.

**Record nits.** `docs/decisions/2026-10-18-minty-quail-speckled-hare.md` and
`2026-10-18-minty-quail-jolly-ibis.md` end without a final newline; line 14 of
`2026-10-18-minty-quail-merry-osprey.md` is 155 columns (a trailing space was reported there and a check on
2026-11-23 found none: the line is rewrapped to the width its neighbours keep).
