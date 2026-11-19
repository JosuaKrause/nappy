# polite-tapir — Step 4's last pull request: a beat goes first in a unit that has not drawn, and a mark's rigged row is laid straight ahead of her · 2026-11-18

**What it is.** Placement step 4's last pull request (polite-tapir's `placement-by-construction.md`,
step 4: the beats become rigged marbles), the design's pull request 4
(`.claude/briefs/designs/placement-step4-rigged-marbles-design.md` in the orchestrator's checkout, not
tracked), built by Opus agents from the written design and the player's board answers, since
Fable's quota was out; the player chose that it waits for Fable's review before it merges (inbox
#1547). It closes the item: step 4 was the last step left, so `placement-by-construction.md` goes.

**What was asked and answered** (the board, breezy-magpie and inbox #1549):

- To beat-changes-its-unit: "repeating the day has the exact same preconditions. if the player does
  something differently different things might happen. if the player were to do exactly the same
  everything would behave exactly the same. beats are marbles, yes" (inbox #1521 in breezy-magpie).
- To beats-on-her-street, which asked whether day 6's second man shouting and day 7's second van
  are laid on her street or as the item's letter had them: "the draw doesn't have to happen at the
  point where she touches the mark. the bag gets the biased bag in front (via the chained bags
  mechanism) and the next draw (whenever that happens) will guarantee the shouting man" (inbox
  #1520 in breezy-magpie). The first build read "the next draw" as the next unit of the city to
  draw, wherever it was; review 1 measured that he was then in her view on none of 12 walks, the
  van neither, against 9 of 12 each on main, which loses what he is rigged for (olive-koala 2: "the
  yeller is guaranteed to encounter a yeller in the next three events").
- To man-and-van-met, which put those numbers to the player with the options (as built; the next
  stretch to fill in ahead of her on her way; on her street just out of view, as on main): "why?
  you would draw only for the path and only just ahead" (inbox #1549). **Read as** (the
  orchestrator's, written back on the board): the rigged bag stays in front, but only a place on
  her path just ahead of her may take its draw; the stretches just ahead have already filled in
  when she reads the mark, so the draw lands on the first empty place on her path just ahead, out
  of her view, the way a beat is laid on a place a filled stretch left empty. Which of the measured
  rules below meets that best was the orchestrator's choice inside those words, not put back to the
  player: straight ahead on her branch.

**What was built.**

- **A beat goes first in a unit that has not drawn.** `WalkSiting` is handed the day's units
  (`DayUnits.unit_of()`, an index filled as the units are grouped) and offers a beat laid ahead of
  her the free locations of units that have not drawn first, nearest to walk to first, then those a
  drawn unit left empty, `LOCATIONS_A_LOOK` over both. The unit of the location a beat takes is told
  (`PlacementUnit.rig()`, `unrig()` on a move, `rigged()`); a location given back after its unit
  drew is recorded as drawn with nothing on it. `UnitDraw` judges a unit among the beats rigged in it
  and in every unit touching it, drawn or not. Nothing is drawn round a pick any more: the ground
  drawer (`WalkSiting.use_the_ground_drawer()`) and its give-up are deleted.
- **A mark rigs the next draw on her path, and it is laid straight ahead of her.**
  `ResistanceDirector._rig_her_route_for()` rigs day 6's man shouting and day 7's van
  (`ResistanceSteps.Step.rigs_the_next_draw`, `EventManager.rig_the_next_draw()`); the director
  puts each on the list of what her walk lays (`EventDirector.rig_the_next_draw()`), holding the
  rigged rows alone, and the next look lays it (`WalkSiting.lay_just_ahead()`) on the first free
  location of its own ground, nearest to walk to first, within `JUST_AHEAD` (the stream radius,
  900px) down her branch and straight from her, within `PATH_HALF_WIDTH` (five tiles) of a cell of
  her branch, ahead along her heading within five tiles of her line of travel, and with none of what
  it draws in the camera's view grown by its lead and a tile. The ground there has drawn, so it
  takes a location a drawn unit left empty, its unit is told as for a beat, and it is in the world
  on the frame it is laid. It joins the day's plan when first laid, as a place from her route's bag
  does (`EventDirector.is_from_her_route()`), and the run log's `ahead` line says where. Day 11's mast
  still goes through her route's bag and is laid as a beat.
- **Deleted, nothing reaching them:** the street-beat path of `WalkSiting` (`_on_her_street()`,
  `STREET_HALF_WIDTH`, the siting's day; its view test lives on in `_could_be_in_her_view()`),
  `EventDef.is_met_on_her_street()` with `meet_on_her_street()` and its catalogue call,
  `SitedGround.is_a_wall_by_cost()`, `ResistanceSteps.TASK_CONTACT_WITHIN_THE_NEXT` and
  `VAN_WITHIN_THE_NEXT`; and the first build's bag in front of the units' draws
  (`UnitDraw.rig_the_next_draw()`, `drew_from_the_front()`, `MarbleDraw.Rigged` and its rigged draw).
- **The day 6 and day 7 suites hold the meeting**: reading the mark, then walking the day's longest
  route until he is laid and on the way she was heading after that, he is laid out of the camera's
  view, comes into her view, and (the man) is in the world once she is near, a check counted on
  every walk.

**What it measured** (each probe on the branch, against the runs after pull request 3 and on main
in the design's folder):

- `tests/probes/walk_rows.gd`, the item's acceptance run: `WC all 0 0`, no route tile cut off from
  home; `WU all 0 91750 15597 137 28`, the longest chain 28 as on main; `WS all 136 29 107 101`,
  136 beats laid or moved (all day 3's fire: the probe lays no crew, which needs the built city's
  walls), 29 in a unit that had not drawn, 107 on a location a drawn unit left empty, the nearest
  row a unit drew 101px from a beat; `WR all 107347 3 1 0 2`, of 107,347 units drawn over the
  seeds and days, 3 drew otherwise than on the same day drawn whole with no walk, all on day 3. The
  2 the full run left unexplained were in units a beat stood in and was moved off before the walk
  ended; the probe now counts a unit a beat ever stood in, and day 3 run again with that count
  prints `WR 3 7674 3 3 0 0`. The worst siting tick of day 3 over the seeds is 45ms against 132ms
  after pull request 3 and 153ms on main. `WV`, `WK` and `WD`, what she meets per walk by view and
  kind of ground, are identical to the run after pull request 3: no row moved. `WZ` is identical
  to main's.
- `tests/probes/m179_fire_on_her_way.gd`: the fire seen on 6 walks of 12 (4 after pull request 3,
  5 on main); the 5 walks that end with it never in the world light it at dusk; a siting attempt
  17.8ms on average over 511 attempts (18.0 on main); the worst frame of any walk 937ms (983 on
  main); no wait on undrawn ground.
- `tests/probes/m180_crews_on_her_way.gd`: every crew a day drew is laid and met, 10 of 10.
- `tests/probes/calm_pelican_day7_van_met.gd`, twelve walks each of mark, task, calm and home (the
  probe's walk follows shortest paths, not the route tree, so it turns off her branch where a
  player may), each rule run on the same tree, and main beside them in a checkout of main on the
  same machine, which matched review 1's figures:

  | Where the rigged row is laid | man shouting: seen (laid) | van: seen (laid) |
  |---|---|---|
  | main: her street just out of view, after a route bag of two | 9 | 9 |
  | (a) the first free location on her branch, out of view, within 900px | 10 (12) | 5 (11) |
  | (b) the same, straight ahead of her only (built) | 8 (11) | 8 (9) |
  | (b) first, then (a) in the same look | 9 (12) | 5 (11) |

  Under (b) the man is laid 306 to 833px from her and the van 295 to 600px. Under (a) the van went
  about 320px to her side, up a fork or round a turn of her branch she did not take: the view is
  wider than it is tall, so the nearest place out of view is often beside her. (b) first with (a)
  in the same look kept that, since the fallback fired on the first look after the mark, before
  her line had moved on to a free place straight ahead. A rigged row in front of every unit's
  draw, as this pull request first built it, was in her view on 0 of 12 walks for either (review 1).
- `tests/probes/placement_rows.gd` prints what it printed before the change, line for line.

**Departures from the written design, each open to Fable and the player.**

1. **Day 6's man shouting and day 7's van are laid by her walk, straight ahead of her, rather than
   as either of the design's Q1 answers.** The design's pick (b), the street-beat path, is deleted;
   what lays them now is the beats' own siting on her branch, narrowed to straight ahead.
2. **The rigged bag holds the rows alone.** `MarbleBag.rig()` fills a rigged bag of `x` with marbles
   taken from the bag being drawn from; the rows a mark rigs are laid by her walk instead, so there
   is no bag to take the rest from, and "the next draw" on her path is his. The guarantee is no
   longer "within the next two events handed out on her route" (olive-koala 2's "in the next three
   events"), which the answers replace.
3. **Which units may differ by her path is wider than the design said.** Its acceptance read
   "`differ` equals `beside-a-beat`", but a unit is judged among the draws of the touching units
   drawn before it, so a difference can carry along touching units, and a beat moved off a unit
   leaves what that unit drew round it as drawn (the design's 3.5). `WR` prints both: carried,
   followed from a unit a beat stands or stood in or beside through touching units that differ, so
   two touching units that differ do not excuse each other (none measured), and beside a beat.
   `tests/test_event_manager_units.gd` holds that no unit differs out of nowhere, by the same walk.
4. **What the design did not name:** the run-log line where a rigged row is laid; the siting treats
   a location no unit holds as drawn; the probe's walk is handed its unit draw, which it lacked, so a
   beat it laid was rigged in units nothing drew; the events skill's own line that every unit's draw
   is the same whatever her path is narrowed besides its `plan-and-excitement.md` paragraph.

**Not built, open to overturn.** (b) first with a *delayed* fallback to (a): straight ahead for a
few looks, and the rest of her branch only once none of them found a place. It would lay the man
and van on the walks where (b) lays nothing before the probe's walk ends (1 and 3 of 12), at the
cost of a wait constant and of the side places that (a) showed she often misses; not measured.
