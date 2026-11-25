# minty-quail — Row 3a's first pull request: the dawn asks the row, and the burnt frontage's scar id is the catalogue's · 2026-11-19

**What was asked.** Row 3a of minty-quail's `event-interface.md` (the dawn and the walk's ground ask rows and plans),
which waited for placement to close. Every caller asks an event through its interface and never reads its settings
(inbox #1173 in gray-dolphin, statement 16; **designing-classes**, "Fields are not API"). An Opus design cut the row
into six pull requests (kept outside the repository, in the orchestrator's design folder); this is the first, built
by a Sonnet agent (#1575). It also settles polite-tapir's standing layer break "`RowGround`'s
`City.BURNT_FRONTAGE_SCAR` ... which waits for nothing" (`standing-layer-breaks.md`, inbox #1268 in olive-ferret).

**What was built.** The row (`EventDef`, data) answers nine new questions the dawn's files asked of its fields:
`is_a_one_shot()`, `is_scenery()`, `stands_on(tile)`, `ground_kinds()` (a copy), `sidewalk_lane()`,
`lies_as_a_spread()`, `burns_its_front()`, `comes_again_after()` and `own_first_day()` (the first day of a row, or of
its act for a scripted row, which `SealPlanner._effective_first_day()` used to work out and which is deleted). The
plan (`EventPlan`) answers `paces_a_beat()`, `pursues()` and `is_the_same_row_as(other)`. Every read in the dawn
lesson and spoilers, the day's events, the plan's own reads of its row, the scheduler (whose opt-out line goes, so it
is typed), the mast sites, the plan builder, the row's ground, the ruled location ground, the street invalidation,
two street rules and the seal planner asks a method; `tools/field_reads.txt` loses 45 lines. The burnt shell's id
is `EventCatalogue.BURNT_SHELL_ID`, its one statement: the catalogue's two literals use it, the row answers
`burns_its_front()` through `Aftermath.leaves_the_scar(scar_id)` (added beyond the design, since reading
`Aftermath.scar` would be a new field read), `CityFronts` reads the catalogue's constant, and
`City.BURNT_FRONTAGE_SCAR` with `RowGround._burns_its_front()` and the `City` exception in `tools/layer_map.py` are
deleted. `RowGround`'s cache keys are built from the same answers, so each key string is unchanged; the placement
probe's output is identical on the base and the branch.

**Open to overturn (the designer's, built on its picks):** writing the plan's own question where a line touched
`plan.row().x()` (fork F1 of the design, from rule 1 of event-interface.md's section 2.1); the method names; the
`Aftermath.leaves_the_scar()` addition.

**Rejected** (the design's): `is_scripted()` on the row (section 4.1), since `own_first_day()` leaves it asked by
nobody (`act()` stays for row 4a, whose test rewrite asks it for `tests/test_acts.gd`'s read of `act_tag`); a cache key string the row gives (`ground_key()`, section 3), since the keys built from the row's
answers are the same strings.

**The item.** Row 3a stays open in `event-interface.md` until its last pull request; polite-tapir's
`standing-layer-breaks.md` loses the burnt frontage; the scheduler leaves `field-reads.md`'s list of untyped files;
the seal planner's copy of `first_day` in section 4.1 becomes its question.
