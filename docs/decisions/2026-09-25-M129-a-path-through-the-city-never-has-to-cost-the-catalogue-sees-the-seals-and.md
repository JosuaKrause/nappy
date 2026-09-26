## M129 — A path through the city never has to cost · the catalogue sees the seals and the wall, built 2026-09-25

**What is built.** `SealPlanner.plan_day` and `RegionPlanner.plan_day` run before
`EventScheduler.build_day`, so their bodies were never in `already`, the set the three candidate
rules (`_leaves_the_route_junctions_open`, `_leaves_the_routes_sidewalk_open`,
`_leaves_a_pacing_beats_opening`) check a catalogue row against. `build_day`'s `standing` argument
(the seals and the region wall, passed by `EventManager.start_day`) now reaches those rules through
a per-candidate context of `already` plus `standing`; `_room_around`'s spacing still reads
`already` alone, so density stays a question about the catalogue's own rows. `tests/test_seals.gd`,
`_test_the_catalogue_sees_a_seal_at_a_route_junction`, plans days as `start_day` does and asks every
catalogue row the junction question against the whole day: 8 failures against the old scheduler
(`cafe_tables`, `ice_cream_van`, `busker`, `market_stall`, `leaf_blower` beside a seal or the wall),
none with it.

**Two probe bugs, and most of the headline was theirs.** The probe passed no `doors` and no
`standing` to `build_day`, so `_clear_of_the_doors` was never exercised in the measurement, and it
missed one of `_a_line_has_to_avoid()`'s five exemptions, a pursuer, so it blamed `alley_robbery`
and `charging_dog`. Six seeds, one day per act:

| scheduler | probe `doors` | probe `standing` | zero-cost-line routes |
|---|---|---|---|
| before | empty | empty | 208/299 (69.6%) |
| before | real | empty | 236/299 (78.9%) |
| before | empty | real | 214/299 (71.6%) |
| before | real | real | 236/299 (78.9%) |
| after | real | real | 239/299 (79.9%) |

So the doors wiring accounts for 28 of the 31 routes, and the scheduler change for the last 3.

**Paths checked and left alone:** `_ensure_one_usable_park` and `_ensure_the_city_is_still_
walkable` only remove, the city rule's one monotonic exception, so they cannot close a junction;
masts are exempt from the guarantee; `WalkSiting` already receives the day's full plans; scars
reproduce an earlier day's placement and cost a route by design. What stays open — the wall and
seals against each other, a carriageway roadblock, the calm-ground pass and the resistance's
`spawn_extra` sites — is in `TODO.md` under M129.
