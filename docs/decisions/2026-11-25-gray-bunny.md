# gray-bunny — A sent cyclist keeps placed plans out of his field · 2026-11-26

The events skill's rule "nothing else happens inside a lethal event's field" is enforced at placement by
`StreetInvalidation.room_around()` for every plan that keeps its field clear (`EventPlan.keeps_its_field_clear()`:
it ends the day, is not a wall and does not pursue). Every lethal row a day places on a tile is a wall or a pursuer,
both exempt, so the one lethal row the rule binds is the cyclist, which the director sends at her and no dawn phase or
unit places. The director asked the rule in one direction only: a row it sends ahead of her (the dog walker, the
patrol, the convoy) kept out of the fields placed plans keep clear, and nothing kept a placed plan out of the field of a
cyclist it sent. The finding is the Opus review of PR #1795 (amber-ibis), left open in the record amber-ibis-quiet-stork.

**What was built.** `EventDirector.clear_to_send()` builds the sent row's plan once and refuses a row whose plan keeps
its field clear where a placed, unspent plan of the walk is nearer its route than its field reaches
(`_keeps_its_own_field_clear()`, measured as `EventPlan.gap_to()` against `EventPlan.field_reach()`, 134px for the
cyclist). Every placed plan is asked, a wall and a pursuer included, since what is exempt is a field kept clear, not a
thing standing in one. As he is sited, `_its_field_holds_while_its_badge_is_up()` works out the route he is created on
once his badge has run (as `EventsAhead._warn_down_her_line()` builds it) for her shifted along her line by up to
`Tuning.RUN_SPEED` times his `warned_for()` and a tile, either way and every half tile, and refuses him where any such
route has a placed plan in its field, so his badge is not withdrawn at arrival by a plan standing when he was sited
(minty-dolphin #852). A cyclist marble with no room waits (`_waits_for_room()`, `_sent_waiting`) as a row sent ahead of
her does (calm-pelican-6). `tests/test_event_director.gd` holds a café on his way refusing him and a spent one not, a
café past his route's end within her badge-time walk refusing him and one further off not, and the waiting for both the
patrol and the cyclist. `tests/test_events_scheduler.gd` walks the shared city's planned days 2 to 14, twelve spots down
the arterial's sidewalk each way: on main's director it fails both of its checks (cyclists sent with a placed plan in
their field on every day), on this one it passes, with a guard that fields were found.

**The measurement** (`tests/probes/gray_bunny_cyclists_sent.gd`: six generated cities, days 1 to 14, a whole day of
walking the arterial's sidewalk per day, the director handed the day's whole plan):

| Director | Rows handed out | Cyclists sent | A day | With a placed plan in his field | Badge withdrawn at arrival |
|---|---|---|---|---|---|
| main | 815 | 66 | 0.79 | 41 | not counted |
| the field check, a cyclist with no room holding the route | 789 | 63 | 0.75 | 0 | 13 |
| and the badge hold, still holding the route | 732 | 48 | 0.57 | 0 | not counted |
| and waiting for room (built) | 808 | 28 | 0.33 | 0 | 1, not by a plan |
| measured, not built: his route cut two tiles past her | 806 | 36 | 0.43 | 0 | 2, not by a plan |

The built row was taken again on the finished branch. **Siting him elsewhere does not keep his rate.** His route runs from
just out of sight down her line, on her own side of the street as the player asked (the docstring of `EventDirector._toward_her()` quotes
the words), to
as far past her as he started, and a placed plan within his field of the stretch of her line ahead of her refuses him
whatever place down that line he starts from, since every start puts that stretch on his route. The next box would send
him down the crossing street, which is not the row (`TOWARD_PLAYER`: traffic on her line she answers with a route). The
one freedom siting has is how far past her the route runs: cut two tiles past her, the field asks only her side of him
and a margin, and the rate comes back to 36 of the 66, at the price of a pass that ends two tiles behind her and leaves
from there, which changes what a pass costs (`docs/COSTS.md`). The rest of the fall is the badge hold (63 to 48 while a
cyclist holds the route) and the waiting's cadence (48 to 28): a cyclist that waits is asked again only on the clock's
turns (sent-ahead-pace), where one holding the route is asked every second but stops every other row behind him, all
handouts falling by about a tenth (808 to 732). **On the probe's walk cyclists fall from 0.79 to 0.33 a day**, a felt
difficulty change on days 2 to 14, reported plainly and not tuned.

**Choices open to overturn.**

- The badge hold, sampling her walk along her line while his badge is up: the builder's, from minty-dolphin #852's rule as
  the convoy applies it (`_holds_while_its_badge_is_up()`). Without it 13 of 63 cyclists would have their badge
  withdrawn at arrival.
- A cyclist with no room waits rather than holding the route: the builder's extension of calm-pelican-6. The plainer
  alternative, holding, keeps 48 cyclists and cuts every other row by about a tenth.
- His field measured as `field_reach()` along his whole route, behind her included, as `room_around()` measures every
  placement. The alternative measured above asks it only to two tiles past her.

**Left open.**

- What a unit draws, or a beat her walk lays just ahead of her, while a cyclist is out is judged among the walk's plans
  and not his live field (the placement side asks plans, not live sent rows). A check inside a unit's draw against a live
  cyclist would make the unit's draw depend on when she walks past, which the events skill rules out ("The day follows
  from its seed": every unit's draw is the same whatever her path, but for the beats); drawing the units his field
  reaches before he is created, as a place the resistance sends her to draws its ground first, keeps the draw as it is.
  Which of the two is wanted is a question for the orchestrator.
