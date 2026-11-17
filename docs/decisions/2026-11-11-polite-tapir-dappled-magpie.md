# polite-tapir — Step 5's seam: a walk's own bag is read through the day spec, the dawn phases ask the context for catalogue rows, and a unit's bag through UnitBags · 2026-11-17

**What it is.** The first of placement step 5's three pull requests (polite-tapir's
`placement-by-construction.md`, step 5: the escape city's draw is the same unit draw), built from
Fable's design (`.claude/briefs/designs/placement-step5-escape-unit-draw-design.md` in the
orchestrator's checkout, not tracked). It changes nothing in play: the placement fingerprint
(`tests/probes/placement_fingerprint.gd`) prints the same lines at main and at the head.

**What was built.**

- A walk with a bag of its own is read through the day spec, `DaySpec.walk_bag()` and
  `walk_bag_rows()`, an empty bag meaning none.
- The dawn phases (ambient, scripted, one-shots, moments, the dawn draw) ask the day's context for a
  kind's catalogue rows, `DawnContext.catalogue_rows(kind)`, which answers none for a walk with its
  own bag, rather than the catalogue directly.
- A unit's bag is asked of one object, `UnitBags.bag_for(unit)`, which `UnitFills` extends for a
  day; `UnitDraw` is handed a `UnitBags` and asks it once a unit.

**What is left of step 5:** the ground (a walk with no corridor laid out along its own streets,
one marble a unit), after step 4's third pull request, and the switch (the escape drawn by the unit
draw, the old draw deleted, the bag's empty marbles from 1 to 9), both in the item.

**Proposed, not asked for, open to the player:** the design's picks this pull request builds (an
empty walk bag means none, with no yes-or-no beside it; `UnitFills` extends `UnitBags` rather than
a wrapper; `DaySpec.bag` stays a field the suites set), and one the design did not foresee:
`UnitFills.of()`, now read only by its own file and its suites, is a kept line in
`tools/test_only_members.txt` rather than made internal, which would rewrite `test_unit_fills.gd`'s
per-cell checks.
