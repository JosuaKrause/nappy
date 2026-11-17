# polite-tapir — Step 4's second part: the row and the plan answer what her walk's siting asks · 2026-11-17

**What it is.** The second of placement step 4's four pull requests (polite-tapir's
`placement-by-construction.md`, step 4), built from Fable's design
(`.claude/briefs/designs/placement-step4-rigged-marbles-design.md` in the orchestrator's checkout,
not tracked). It changes nothing in play: the placement fingerprint prints the same lines at main and
at the head.

**What was built.** The row answers what her walk's siting asks of it: `EventDef.is_sited_from_her_walk()`,
`stands_at_a_front()`, `is_a_set_piece_on_her_way()`, `is_a_mast()` and `is_met_on_her_street()`,
the last set by `meet_on_her_street()` on day 6's man shouting's catalogue row in place of a branch
keyed on that row's id. The plan takes a judged place in one call, `EventPlan.stand_where(sited)`
(place, route, facing, role), and turns with `face(direction)`. The scheduler, the director,
`EventsAhead` and the streaming ask these instead of reading fields; fourteen lines leave
`tools/field_reads.txt`.

**What is left of step 4:** the old roll deleted, with `WalkSiting` a file of its own, handed in; and
the beats laid in a unit before it draws, waiting on the board questions `beats-on-her-street` and
`beat-changes-its-unit`.

**Proposed, not asked for, open to the player:** `stand_where(sited)` in place of the events'
interface design's `place_at(at)` (the design's pick); and the builder's `OnHerWay.pastes_a_front()`,
which the design did not name, added so that the row asks its walk part rather than reading its field.
