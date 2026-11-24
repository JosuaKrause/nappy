# minty-quail — The ground a deadly event shuts is one stated fact · 2026-11-23

minty-quail's `event-interface.md`, section 7, answered point 6: the disc a plan shuts for the day's
routes and reach (`EventPlan.blocking_radius()`) used the row's field core where the row ends her
day at its catch, and the ground a row that ends the day shuts was stated four ways. The player's
word on it: whatever is the correct implementation (inbox #1278 in olive-ferret).

**Built.**
- `EventDef.catch_shuts_within()` is the one statement: the catch (`lethal_reach()`) for a row that
  ends the day and does not move along a route of its own (`moves()`), 0 for every other row. A
  pursuer waiting at its post counts, since it notices her before she could come within its
  catch; the day's rules already read the alley robber and the charging dog that way, and the
  one-sidewalk rule needs the pair (the record polite-tapir-golden-egret rejected a version that
  missed it).
- `EventPlan.blocking_radius()` is the wider of the body and that ground, and `obstructs()` is
  `blocking_radius() > 0`. `WalkGround.held_by()` holds the body's pieces plus that ground
  (`EventPlan.catch_shuts_within()`); its own test of `moves()`, `ends_the_day()` and `pursues()`
  and its read of the row go.
- `OneSidewalkOpenRule._closing_radius()`, the roadblock's special case, is deleted: the hunting
  roadblock's guard catches at 28px inside its 64px band, so the band is what every rule reads at
  every heat. Its disc goes from the field's 86px core to the band.
- `EventPlan.clearance()` measures the catch to her centre (no `+ her_reach`), as the park cordon
  tests her centre; the term never decided an answer.

**Kept apart.** `EventScheduler.clearance_around_her()` stays at the outer radius: it is the warned
ground, and a row whose outer radius covers her has already spent her notice before she takes a
step (PLAYTEST-94 9). The ground a deadly event shuts and the ground it warns over are two facts.

**Measured** (`tests/probes/minty_quail_blocking_reach.gd`, 18 seeds, days 7 to 14, heat 4, main at
d3faeaf8c and the branch): the hunting roadblocks placed are the same in number each day (80, 122,
91, 63, 53, 83, 361, 76 on days 7 to 14); the tiles their discs shut fall from 7928, 17120, 8974,
6210, 5138, 7274, 36190 and 6736 to 7128, 15900, 8064, 5580, 4608, 6444, 32580 and 5976; the route
tiles home no longer reaches over the day's shut ground are none on both. `placement_fingerprint.gd`
(the escape's and the building's `FP` lines included) and `cordon_placement_fingerprint.gd` come out
line for line the same.

**Rejected.** Narrowing `clearance_around_her()` to the shut ground (it brings back the flashing
mark at the start); a pursuer's post shutting nothing (it loosens four day rules and drops the
pursuer half of the one-sidewalk rule); changing the cordon sweep's own oracle
(`tests/park_cordon_sweep.gd` adds her body to the catch, written apart from the cordon's rule so
it checks the cordon against nothing of its own).

**Found, left for entries of their own.** `WarningBoard.warn_about_the_ground_she_is_on()` measures
the gap to the radius that ends the day from the core, so the doubled red mark over her head treats
the hunting roadblock's guard as 86px and the masked man as 28px against catches of 28px and 23.5px
(a cue). "Where she touches a plan from" is derived twice, in `RuledRoadblockGround._touched_from()`
and `ResistanceDirector._touched_from()`. The route rig's own hunt for a standing lethal place
(`EventInstance.is_a_standing_lethal_place()`) is a fifth statement of the same fact and moves to
`catch_shuts_within()` in a second pull request.

**Checks that held it.** Each fails with its one-line revert: `blocking_radius()` reading
`core_within()` (the hunting roadblock's case and the hunting roadblock beside a pole in the
one-sidewalk suite), `moves()` dropped from `catch_shuts_within()` (the cyclist), pursuers left out
(the alley robber), `+ her_reach` restored in `clearance()`, and the pursuer exclusion restored in
`held_by()` (the escape roadblock's catch piece in the finale rig). The ring inside the catch fails
when the catch disc is widened to the core. The single roadblock alone on an eight-tile street
passes with the core read, since one disc cannot close both sidewalks there, so it holds nothing
of this.
