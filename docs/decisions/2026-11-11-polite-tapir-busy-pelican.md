# polite-tapir — The dog walker, the patrol and the convoy are sent just ahead of her as marbles of her route's bag (placement step 2) · 2026-11-16

**The ask.** The dog walker, the police patrol and the military convoy are not drawn at the beginning of the day; they are
put in the world when she is close by, just ahead of her, so that an encounter is guaranteed (inbox #1460). This is the
pull request #1477, part A of step 2 of `placement-by-construction.md`: the three rows sent ahead of her, each on its first
leg. The route of each worked out as it goes is the record `polite-tapir-tall-ibis`, which finishes the step; the street
rules are the record `polite-tapir-golden-egret`. The pictures and the figures below are in
`docs/evidence/polite-tapir-sent-ahead-arrivals-2026-11-16/` (its README has the commands).

**Readings taken without asking the player**, each the orchestrator's and open to the player's correction:

- **The dog walker walks toward her**, down her own sidewalk, as the loose dog comes: a guaranteed encounter asks for it.
- **Day one's floor** is two dog walkers among the first three marbles drawn on her route (the design's floor of at
  least two on day one, PLAYTEST-05 6), by a rigged bag (inbox #561 in coral-bunny). Where she has a sidewalk ahead of her they are two of
  the first three things sent at her; one drawn where she has none waits for room.
- **The board question `day3-charging-share`**: day 3's charging dogs keep the player's share of the bag, two marbles in
  sixteen (inbox #566 in feathery-stork), one declared number (`EventDirector.ROUTE_BAG_SHARE_OF`). Built on the
  orchestrator's pick; the player has since answered the question, keep the share, on inbox #1460, so the number stands.
- **The board question `sent-ahead-pace`**: the three come in place of some of what the director sends, at the director's
  unchanged clock (`EventDirector.AHEAD_INTERVAL`, a handout every 11 to 26 seconds of walking), which the player accepted
  as correct (inbox #1460, the orchestrator's reading of the answer). A row that waited for room is sent on a later turn of
  that clock, and a row that finds no room spends no turn.
- **A rigged marble that waits is met later, or never** (a day-one dog walker, a return patrol). The player accepted that
  narrowing for a place's marble (inbox #650 in mossy-beaver); for a sent row it rests on the orchestrator's reading of
  `sent-ahead-pace`, pace over order. `docs/EVENTS.md` says so where the rigs are listed.
- **The sent dog walker keeps the catalogue row's price**: being just ahead is about where, not what it costs, so its bark is at a
  drawn point when it is created, as a dog walker she walked up to is.
- **The convoy is warned of first**: its screen-edge badge alone for a second, then it is created in its lane just out of
  sight, as day 13's column is.
- **No vehicle on a precinct's paving** is not a request of the player's but the game's rule for an event car, which every
  sent patrol and convoy now depends on. It is held here for where she stands as the car is sited, not for a her who walks on
  the way it drives (the orchestrator's decision after the fourth review).

## What was built

- **`SentAhead`** (`src/events/sent_ahead.gd`, data): two settings, `warned` and `from_either_end`, a value type like
  `DaySwitch`. The design's third setting, whether the route goes on while she follows it, is the next pull request's.
- **`EventDef`** `send_ahead(how)`, `is_sent_ahead()`, `is_warned_in_its_lane()`, `may_come_from_either_end()`,
  `as_sent_ahead()` (the copy the director sends; every copy is validated as it is made), `age_at_a_point_of_its_beat()` and
  `nearest_it_is_created()`; `is_drawn_by_units()` answers false for a sent row, and `StreetShare.A_STREET` with its branch of
  `takes_of_a_street()` is deleted. The dog walker and the patrol are `send_ahead(SentAhead.at_once())` (created at once, no
  badge, since each is slower than a walk and neither is lethal, PLAYTEST-145 18-23); the convoy is
  `warned_first_from_either_end()`. The rows stay `MAP` for whatever else places them (the escape's trucks, day 13's column,
  the raid, a scene recipe's tile).
- **`EventDirector`** puts the sent copy of each sent row in the route's bag, weighted like every other row; owes a dawn moment
  of a sent row as a marble; rigs day one's two dog walkers through `rig_her_route()`; sends the convoy to
  `_in_the_lane_beside_her()`, the dog walker to `_toward_her()` and the patrol to `_toward_her_on_the_road()`. A sent row with
  no room (`clear_to_send()`: the region doors, and a first leg starting within 64px of a placed plan or running through a field
  a plan keeps clear) spends its marble, waits on `_sent_waiting`, and is sent on a later turn ahead of the next marble; the
  turn that found no room is asked again a second later (`SENT_RETRY`). The checks apply to sent rows only, so the cat, the
  loose dog and the cyclist are sited as before. `_patrol_toward_her()` is deleted; `ordinary_route_marbles()` shares out the
  bag with `ROUTE_BAG_SHARE_OF`; `--force <a sent row>` forces the sent copy.
- **The convoy's siting**: its lane is the carriageway of the street she is beside; it drives toward her or from behind her (a
  coin flip on the director's stream), from the other end where the first has no room; its place is level with her, just out of
  sight up the road (`PendingWarning.in_its_lane()`, which takes a lane as a point and a unit direction so either axis serves);
  its leg runs past her to the far edge of the next junction box.
- **A sent car's leg and its way out are kept to carriageway** at one choke point, `EventDirector.leg_in_the_lane()`: a leg is
  sent only where every tile of the drive, to `Tuning.OUT_OF_SIGHT` (420px) past where she stands or to the leg's end, is
  carriageway and nothing on it stops the car (a solid, a closed street, the map's edge).
- **Deleted**: `UnitRoom`'s whole-street room, `MarbleDraw`'s whole-street cases, three rows of
  `EventScheduler.GROUND_WEIGHTS`, `EventDef.meets_her_with_its_telegraph_spent()`, `walk_rows.gd`'s whole-street column.
- Docs: `docs/EVENTS.md`, `docs/MECHANICS.md`, `docs/TELEMETRY.md`, `docs/SCENE_RECIPES.md`, `docs/ARCHITECTURE.md`,
  `docs/COSTS.md`, the events skill's `warned-first.md` and `fields.md` and the cues skill's badge bullet (each flagged to the
  player in the description); a scene recipe's `route_bag` accepts a sent row.
- Tests: `tests/test_sent_down_her_line.gd`, `tests/test_sent_cars_off_the_paving.gd` (an outcome sweep over every street into
  a paved box), `tests/test_unit_room.gd` and the director's, scheduler's and manager's suites, each mutation-checked.

## Measured

- **Where the car drives in her sight, with her standing** (a throwaway probe over every sidewalk tile beside a carriageway,
  four cities): at the first rethink's head the patrol's legs put the car on paving in her view in 1.8% of 28,848 legs and the
  convoy's in 3.3% of 31,420, and drove into the map's edge in her view in 3.7% and 6.8%; at the head, none of 24,236 and
  26,388. The head sites 16% fewer legs on that sample, which over-weights places near a paved box or the map's edge; on a
  day's walk it costs 0.0 met a day.
- **A day's walk** (four cities, 36 days): 9.89 things met a day before and after; rows that waited for room 72 and 73; the
  closest two things sent at her 11.20s apart.
- **The route bag's mix** (`olive_badger_route_mix.gd`, 12 seeds by 9 days): met a day 9.7 on main and at the head; mismatch
  against the rows' weights 11.3% on main and 22.4% at the head; return patrols landing in their leg 66 of 120 on main, 80 at
  the head.
- **The sent dog walker's price** is the catalogue row's: a net 16.0 points awake (4.2 asleep) on a pass at 0px from its line,
  15.3 at 20px and 12.6 at 40px, against `docs/COSTS.md`'s 16.1 (4.3), 15.3 and 12.6; `tools/cost-table.sh --check` holds.
- **What she meets on a walk** (`walk_rows.gd`, 18 seeds by 14 days): dog walker 1,190, police patrol 510, military convoy 27,
  cat 631, loose dog 782, cyclist 372, charging dog 78 + 18; route tiles cut off from home 0; the three rows are placed 0 times;
  299 of 299 routes keep a zero-cost line.
- **Day by day** (`olive_badger_route_mix`): a day-one walk meets 6.1 dog walkers, 2.8 loose dogs and 1.6 cats of 10.4 handed
  out, against 5.7 loose dogs and 4.7 cats of 10.3 on main.
- **A convoy sent from behind her, with her walking on**, the fourth review's measurement: 8 of 116 convoys sent seen on paving
  through the real event manager; followed on straight lines from every other sidewalk tile, 400 of 6,636 (6.0%) on paving in
  her view and 2,438 (37%, an upper bound) reaching the map's edge in her view.
- The three placement fingerprints and the observed run-log fixture are unchanged where the day places nothing different.

## Rejected, with the reason

- **Cutting a car's leg short at the paving**: that is the very case where the car, its route run out, drives on over it
  (`EventDeparture.begin()`).
- **Turning a leaving car round at the paving**: the event-car skill's sixth trap, a car must not turn on the spot in her view.
- **The sent dog walker's price from zero** (the bark from zero as a place's dog walker has it): superseded by the catalogue
  row's price, which `docs/COSTS.md` already tabulates.
- **A sent row with no room spending the clock's turn** (`ad98f35e7`): every row that waited then cost her one thing met (8.2 a
  day in the mix, 50 of 120 return patrols in their leg); the turn is asked again a second later instead (`f1628481f`).
- **Holding a car to her view's width at siting** (the third round's brief) in place of `Tuning.OUT_OF_SIGHT` past her: the
  reviewer preferred neither bound; kept, with the sentences changed to say exactly what is held.
- **A full fix for a convoy that overtakes her and leaves over paving**: needs the departure itself kept to carriageway while
  she can see it, which `polite-tapir-tall-ibis` built; this pull request holds the guarantee only for where she stands as the
  car is sited.

## Review

Six reviews, five of them asking changes. The first found the patrol popping into view, the dog walker's price, the charging share, a sent row holding the
route, and untrue sentences; the second the clock's turn spent by a waiting row; the third a car's way out running onto paving
in her view (the leg ended at the last carriageway tile and the car drove straight on); the fourth the convoy that overtakes
her (decided above, and queued); the fifth two places that still said no car is sent where its drive in her sight would leave the carriageway (a test's
lead and the evidence README); the sixth approved the four sentences that fixed them.

## What stays open

What looks wrong for play, none of it fitted: day one is mostly dog walkers; the cyclist falls from day 8 (0.4 to 0.8 a day
against 1.8 to 2.1 on main); the convoy is met at most once a day, by the default `max_per_day` of 1; the mix is further from
the rows' weights than main's, since a bag with the three heaviest rows holds more marbles than a day of walking hands out;
the patrol is met less (98 against 110 over 108 days). All of it rides on the board question `sent-ahead-pace`.
