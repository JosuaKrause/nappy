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
thing standing in one. **The badge hold**: as he is sited, `_clear_on_every_route_while_its_badge_is_up()` works out the
route he is created on once his badge has run (as `EventsAhead._warn_down_her_line()` builds it) for her shifted by up
to `Tuning.RUN_SPEED` times his `warned_for()` and a tile (200px) any way, along her line, across it and both at once,
every half tile, wherever she can stand, and refuses him where any such route has a placed plan in its field, so his
badge is not withdrawn at arrival by a plan standing when he was sited (minty-dolphin #852). The first version sampled
her shifts along her line only; the Opus review of PR #1808 reproduced a withdrawal from one tile's step across her
sidewalk (his place is found level with her own line across the street, `PendingWarning.down_her_line()`, so the step
moves his whole route across), and `tests/test_event_director.gd` holds that case now (her on the outer tile of the east
sidewalk, a café on the outer tile of the west one three tiles ahead: refused as he is sited; with the across shifts
removed he is sent). A cyclist marble with no room waits (`_waits_for_room()`, `_sent_waiting`) as a row sent ahead of
her does (calm-pelican-6), which is open (below). `tests/test_event_director.gd` also holds a café on his way refusing
him and a spent one not, a café past his route's end within her badge-time walk refusing him and one further off not,
and the waiting for both the patrol and the cyclist. `tests/test_events_scheduler.gd` walks the shared city's planned
days 2 to 14, twelve spots down the arterial's sidewalk each way: on main's director it fails both of its checks
(cyclists sent with a placed plan in their field on every day), on this one it passes, with a guard that fields were
found.

**What it costs to ask.** A sited cyclist's hold works out about 275 routes on the hand-drawn street of the director's
suite, about 21ms on the desktop when every one is asked; a refused one stops at its first refusal, so the cost is paid
in full once per cyclist sent, not on every second he waits.

**The measurement** (`tests/probes/gray_bunny_cyclists_sent.gd`: six generated cities, days 1 to 14, a whole day of
walking the arterial's sidewalk per day, the director handed the day's whole plan; "other rows" is every handout but the
cyclists):

| Director | Rows handed out | Other rows | Cyclists sent | A day | With a placed plan in his field | Badge withdrawn at arrival |
|---|---|---|---|---|---|---|
| main | 815 | 749 | 66 | 0.79 | 41 | not counted |
| the field check, a cyclist with no room holding the route | 789 | 726 | 63 | 0.75 | 0 | 13 |
| and the badge hold along her line, still holding the route | 732 | 684 | 48 | 0.57 | 0 | not counted |
| and waiting for room | 808 | 780 | 28 | 0.33 | 0 | 1, not by a plan |
| measured, not built: his route cut two tiles past her | 806 | 770 | 36 | 0.43 | 0 | 2, not by a plan |

With the badge hold across her line as well (the built hold), the three ways a cyclist with no room can go, the choice
the player is asked:

| A cyclist with no room | Rows handed out | Other rows | Cyclists sent | A day | Badge withdrawn at arrival |
|---|---|---|---|---|---|
| (a) holds the route, asked again every second | 670 | 640 | 30 | 0.36 | 0 |
| **(b) waits for room (built)** | **808** | **793** | **15** | **0.18** | **0** |
| (c) holds the route for 3 one-second retries, then waits | 796 | 778 | 18 | 0.21 | 0 |
| (c) holds the route for 5 one-second retries, then waits | 792 | 771 | 21 | 0.25 | 0 |

(a), (c) were measured with a temporary switch in `EventDirector.due()` that the branch does not keep. **On the probe's
walk cyclists fall from 0.79 a day on main to 0.18 as built**, a felt difficulty change on days 2 to 14: his hold now
asks the whole street round her, both sidewalks and the carriageway, since she can cross it in his badge's second, and a
placed plan within his reach of either sidewalk anywhere along the stretch his routes cover refuses him. Holding the
route doubles the cyclists and stops every other row behind him, about a fifth of them (793 to 640); the bounded hold
buys back three to six cyclists for 15 to 22 other rows.

**Siting him elsewhere does not keep his rate.** His route runs from just out of sight down her line, on her own side of
the street as the player asked (the docstring of `EventDirector._toward_her()` quotes the words), to as far past her as
he started, and a placed plan within his field of the stretch of her line ahead of her refuses him whatever place down
that line he starts from, since every start puts that stretch on his route. The next box would send him down the
crossing street, which is not the row (`TOWARD_PLAYER`: traffic on her line she answers with a route). The one freedom
siting has is how far past her the route runs: cut two tiles past her, the field asks only her side of him and a margin,
measured above with the hold along her line only, at the price of a pass that ends two tiles behind her and leaves from
there, which changes what a pass costs (`docs/COSTS.md`).

**Choices open to overturn.**

- The badge hold, sampling her walk any way while his badge is up: the builder's, from minty-dolphin #852's rule as
  the convoy applies it (`_holds_while_its_badge_is_up()`), widened across her line by the review. The alternative the
  review named, a hold along her line only with the docs saying so, keeps 28 cyclists (b) and withdraws a badge where
  she steps across under it.
- **What a cyclist with no room does: (a), (b) or (c), the player's to choose**, (b) built meanwhile as the builder's
  extension of calm-pelican-6. The board question sent-ahead-pace settled the cadence for the three rows sent ahead
  (in place of, at the same clock), not for the cyclist.
- His field measured as `field_reach()` along his whole route, behind her included, as `room_around()` measures every
  placement. The alternative measured above asks it only to two tiles past her.

**The other direction: built.** What a unit draws, or a beat her walk lays, while a cyclist is out could stand inside his
live field, since a unit's draw and a beat are judged among the walk's plans and he is no plan of the walk. A check inside
a unit's draw against a live cyclist would make the unit's draw depend on when she walks past, which the events skill
rules out ("The day follows from its seed": every unit's draw is the same whatever her path, but for the beats). So two
things were built:

- **The ground under his routes draws before his badge goes up.** `EventDirector._may_be_sent_on()` asks the routes,
  then hands the box round every route the hold worked out, grown by his reach and half a tile, to the drawer it is
  handed (`use_ground_drawer()`: `EventsAhead.draw_the_ground_round()`), in squares along the box's long side, each
  drawn out to its corners; where that drew anything, everything is asked again, all before he is handed out.
  `draw_the_ground_round()` draws only undrawn units, each after the units it waits for, so no unit's draw changes. The
  first version drew along his route as he arrived, after his badge was up, where a unit drawn into his field would
  have withdrawn the badge (the Opus review of PR #1808); `tests/test_event_director.gd` holds the order now (a drawer
  that stands a café in his way as it draws refuses him on the turn he is sited) and that the squares cover every point
  within his reach of the route he is sent on.
- **A beat her walk lays is judged among his field.** `WalkSiting` judges every beat among the walk's plans and the
  fields kept clear by what was sent at her and is out now (`_among()`, handed `EventWorld.sent_fields_kept_clear()` by
  `SitingMaker`: a plan of each live instance that came under a warning, is neither gone nor leaving, and keeps its
  field clear, on the whole route it was sent on). A beat is already laid by her path on purpose (the events skill's
  exception for the beats), so this changes no seed rule. `tests/test_walk_siting.gd` holds that a row a mark rigs and a
  beat laid ahead are judged among a sent cyclist, `tests/test_event_parts.gd` that the world answers a warned cyclist
  and neither an unwarned one nor a warned pursuer.

**Whether the pre-draw ever draws.** By the bound, his routes lie about 900px from her at most (a view's half extent and
his footprint just out of sight, `FURTHER_TILES` of 12 tiles, a lateral shift of up to 6 tiles, the hold's 200px, plus
his reach of 134) against `Tuning.EVENT_STREAM_RADIUS` of 900px plus `Tuning.EVENT_DRAW_AHEAD` of 448px, so it is
covered with margin, though by the stream radius alone it is not. On the played radii it is a guard and not a change to
any day. **The guard test** (`tests/test_event_manager_units.gd`: a forced cyclist, her put down beside a row far from
her door, every plan of the walk spent as it stands so that no placed plan refuses him) fails with the band shrunk
(stream radius 1px, draw-ahead 0) and no drawer handed to the director (two units in his field undrawn at his creation),
and passes with the drawer in the same shrunk band; at the played radii it passes either way, so it holds the sum of the
radius, the band and the pre-draw.

**Left open.** A beat laid in the second a cyclist's badge is up, before he exists, is judged among the walk's plans
alone, so one laid inside the route he arrives on withdraws his badge. Nothing lays a beat on that second on purpose (a
row a mark rigs is laid once its marble is handed out, which the clock keeps its shortest wait from the cyclist's, and a
beat laid ahead of her past the streaming band starts about as far from her as his routes reach), and how often it
happens is not measured.
