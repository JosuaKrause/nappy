# downy-llama — The open roadblock covers its own sidewalk and the road, and leaves the far sidewalk whole · 2026-11-16

**The ask.** Shown that a roadblock's band covered its own sidewalk and the road and left about 52
of the far sidewalk's 64px open, the player answered: "okay let's use the one sidewalk has to be
open and match the roadblocks size to one sidewalk + road" (inbox #1465 in spry-plover). Asked then
whether a roadblock off her routes should still close its whole street, as M199 (the roadblock
closes its whole street) asks, they answered: "there are two kinds of roadblocks. one that is open
and one that is closing the street" (inbox #1491). **Read as** (the orchestrator's): the catalogue
`roadblock` is the open kind and is built here; the closing kind stays queued as M199, a kind of
its own rather than a width that depends on where a roadblock stands.

## What was built

- **The body stands on the kerb.** The row is placed on a carriageway lane tile (`ROAD` only: a
  crossing lies in both corridors and has no one kerb, so a band there would not be the open kind,
  and the row no longer lists `CROSSING`), and its body stands on the kerb beside that lane, kept
  where it is along the street: `CityMap.kerb_beside()`, the lattice's geometry with no map, asked
  through `EventDef.stands_at_its_kerb()` (a stationary solid row that spans the street and that
  `pavement_side` does not pin, which is the roadblock).
- **One place decides where a body stands** (designing-classes, inbox #1156 in gray-dolphin):
  `EventPlan.stands_without_a_map()` moves a kerb row onto its kerb, and both `EventPlan.body_at()`
  and `EventFootprints.stands_at()` ask it; `stands_at()` adds only the sidewalk recentring, which
  needs the pavement and so a map. `EventDef.stands_on_its_band_middle()` and
  `stands_at_its_kerb()` no longer overlap. A plan's own map-free reading leaves the recentring out,
  as the day's rules always have for a sidewalk body, and `stands_without_a_map()` says why: it keeps
  a body on its own sidewalk, at most half a tile across it, where the kerb changes what a band
  covers. So the live body, its recorded tiles, its look and the two guards' posts follow the kerb.
- **The band reaches 64px either way from the kerb** (`EventCatalogue.ROADBLOCK_REACH`,
  `GroundShape.band()`), so it covers its own sidewalk and the road, 128px of the 192px street, and
  stops at the far kerb. The picture is drawn at the width it collides at, as before.
- **A plan reads where its body stands** (`EventPlan.body_at()`): its own geometry (`ends()`,
  `distance_from()`, `gap_to()`, `denies()`, `reaches()`, `reach_touches()`,
  `where_it_stands_now()`), and the day's readings of a body: `OneSidewalkOpenRule`,
  `RouteSidewalkRule`, `RouteGroundRule`'s body disc, `DoorClearanceRule`, `EventScheduler.blocked_by()`,
  `RuledRoadblockGround`, `ResistanceDirector`'s touch and the day-13 swap's check that the
  roadblock it puts across a section is drawn out of her view. Every other row's `body_at()` is
  where it was placed. The readers left on `placed_at()` ask which street or tile a plan is on, mark
  the run log's map, space day 13's draws or match a live instance to its plan, where the 16px
  between lane and kerb changes no answer.
- **The region wall's bodies are untouched**: they are pinned (`SealPlanner.sealed_variant()`) and
  stand where they are put, three across the street, with the shapes `RegionPlanner` and
  `SealPlanner` give them.
- **Main's declared table weighs the roadblock at nothing on a junction box**, so no unit draws it
  where `kerb_beside()` finds no one kerb; the probe below counts no roadblock in a box.
- **Tests**: `tests/test_events_catalogue.gd`'s `_test_a_roadblock_covers_its_own_sidewalk_and_the_road`
  stands a roadblock on each carriageway lane of a hand-drawn street of each axis and finds it solid
  from its own frontage to the far kerb with all 64px of the far sidewalk open; against the old
  `band(60)` centred on its lane it fails nine checks ("52 of its 64px open"). The new suite
  `tests/test_city_map_kerb.gd` holds `kerb_beside()`, and `_test_where_a_body_stands_is_read_from_one_place`
  gains the kerb case. `tests/test_event_plan.gd` holds `body_at()`, and
  `tests/test_one_sidewalk_open_rule.gd` a case the kerb decides (a pole on the far sidewalk's outer
  row, level with the roadblock, which the band read at its lane would join into a closed street);
  both fail with `body_at()` returning where the plan was placed. `tests/test_day13_guard.gd`'s far-side test looked at a 128px box round
  the task's first guard while the arrow settled, which on seed 314159, with the body on its kerb,
  took in the rider's box and so decided the roadblock's side from where she read the mark, as the
  decided-once rule (inbox #1185 in gentle-owl) says; the test rests on no roadblock coming on
  screen, so its view is now the guard's own figure, and it passes on main and on the branch.
- **Docs**: `docs/EVENTS.md`'s roadblock row and its pursuit note, and `docs/CITY.md`'s one-sidewalk
  passage, name the open kind; M199's `README.md` gains one line naming it beside the closing kind,
  and its paragraphs on the catalogue roadblock's band and on the sidewalk rules say what is true
  now. The review item `docs/review/2026-11-16-downy-llama.md` asks whether the open roadblock reads
  as "pass on the far side" in play.

## The measurement

Main at 86505121f against the branch, each probe by path from its own tree; the compact output and
the pictures are `docs/evidence/downy-llama-roadblock-band-2026-11-16/`.

- **Roadblocks on her routes' streets** (`tests/probes/downy_llama_route_roadblocks.gd`, new, 18
  seeds, days 7 to 14): 286 to 294 at heat 0 and 61 to 65 at heat 4; beside her routes unchanged
  but day 13's phase, 353 to 360 (361 at heat 4); off them one more on day 7; none in a junction
  box on either tree. A narrower reach on the far side lets the one-sidewalk rule accept a few
  roadblocks it refused.
- **The free line** (`tests/probes/m129_zero_cost_line.gd`): 299 of 299 on both trees, primary and
  with the seals and the wall; the pacing-beat reading 146 of 299 on both.
- **The fingerprints** (`tests/probes/placement_fingerprint.gd`): the escape's differ in one line,
  seed 5 day 14's roadblock one tile along its street; the days in three: seed 4242 day 10 gains a
  roadblock, seed 77 day 10's construction moves two tiles, seed 77 day 14's roadblock one.
- **The escape's roadblocks** (`tests/probes/escape_roadblock_spacing.gd`): the same 62 on the same
  tiles over 40 seeds, none nearer than their two notices; the nearest pair 373px to 385px, the
  bodies now on their kerbs.
- **The day's rows** (`tests/probes/placement_rows.gd`): a few more roadblocks on days 7, 8, 11,
  13 and 14, and moves of one to three among day 13's sidewalk rows.
- **Her routes stay open** (`tests/probes/walk_rows.gd`): no route tile cut off on either tree, and
  no street of her routes ends with both sidewalks closed (0 on both). The probe read every body at
  where it was placed and so counted two such streets on the branch, the band read at its lane
  reaching 16px further into the far sidewalk than the body does; it reads `body_at()` now.

## Rejected

- **An asymmetric shape at the lane**, a band reaching 80px one way and 48px the other: `GroundShape`
  has no such shape, and a new kind for one row would be a second vocabulary for a body that is
  otherwise a plain band about its middle. Standing the body on the kerb keeps the band symmetric.
- **Moving the plan's position to the kerb at placement**: the plan's tile is what the unit draw,
  the ground and the day's records hold, and a carriageway row recorded on a sidewalk-edge point
  would be refused or counted as sidewalk by every reader of its tile.

## Open

- **The closing roadblock** is M199, queued (inbox #1491).
