priority: next

# gray-bunny — Nothing keeps a placed event out of a sent cyclist's lethal field · filed 2026-11-25

**The defect.** The events skill states the rule "nothing else happens inside a lethal event's
field": a lethal event (`ends_the_day()`) keeps its whole outer radius clear of every other event.
The scheduler enforces it at placement through `StreetInvalidation.room_around()`, for the plans
that keep their field clear (`EventPlan.keeps_its_field_clear()`: it ends the day, is not a wall
and does not pursue). Two things leave it binding almost nothing a day places.

- Every lethal row a day places on a tile is a `WALL` (exempt) or a pursuer (exempt), so the one
  lethal row outside both is the cyclist, which the director sends at her and no dawn phase or unit
  places.
- The director asks the rule in one direction only. `EventDirector.clear_to_send()` checks the placed
  plans (`_clear_of_the_plans()`) only for a row sent ahead of her, so a row sent ahead is kept out of
  the fields placed plans keep clear. Nothing keeps a placed row out of the field of a cyclist the
  director sends, so an event can stand inside a lethal field the cyclist then brings.

**Source:** finding of the Opus review of PR #1795 (amber-ibis), which probed
`EventScheduler.role_for()` for every lethal row on days 1 to 14 and found the cyclist the only row
outside `WALL` and pursuit; the record `amber-ibis-quiet-stork` had it under "Left open".

**What a builder does.** Decide with the events skill's contract in hand whether the director's
sending a cyclist also keeps the placed rows out of its field (an ask of the placed plans, the other
direction of what `clear_to_send()` asks today), and hold it with a walk over planned days that finds a
field to ask. A test that passes with the rule deleted holds nothing (**writing-tests**), so the
walk is built together with the code that makes it find one.

**Proposed, not asked for:** the band `next` (the filer's proposal; the player named none).
