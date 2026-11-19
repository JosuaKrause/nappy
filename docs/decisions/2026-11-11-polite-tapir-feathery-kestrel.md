# polite-tapir — Step 4's last pull request: a beat goes first in a unit that has not drawn, and a mark rigs the next unit draw · 2026-11-18

**What it is.** Placement step 4's last pull request (polite-tapir's `placement-by-construction.md`,
step 4: the beats become rigged marbles), the design's pull request 4
(`.claude/briefs/designs/placement-step4-rigged-marbles-design.md` in the orchestrator's checkout, not
tracked), built by an Opus agent from the written design and the player's two board answers, since
Fable's quota was out; the player chose that it waits for Fable's review before it merges (inbox
#1547). It closes the item: step 4 was the last step left, so `placement-by-construction.md` goes.

**The player's answers it builds** (breezy-magpie): to beat-changes-its-unit, "repeating the day has
the exact same preconditions. if the player does something differently different things might
happen. if the player were to do exactly the same everything would behave exactly the same. beats
are marbles, yes" (inbox #1521 in breezy-magpie); to beats-on-her-street, "the draw doesn't have to
happen at the point where she touches the mark. the bag gets the biased bag in front (via the
chained bags mechanism) and the next draw (whenever that happens) will guarantee the shouting man"
(inbox #1520 in breezy-magpie), built on the orchestrator's reading in the item: the mark puts a
rigged bag in front of the bag the units ahead of her draw from (`MarbleBag`'s queue of bags and
`rig()`), and the next unit to draw stands him, wherever and whenever that draw happens; day 7's van
the same way.

**What was built.**

- **A beat goes first in a unit that has not drawn.** `WalkSiting` is handed the day's units
  (`DayUnits.unit_of()`, an index filled as the units are grouped) and offers a beat laid ahead of
  her the free locations of units that have not drawn first, nearest to walk to first, then those a
  drawn unit left empty, `LOCATIONS_A_LOOK` over both. The unit of the location a beat takes is told
  (`PlacementUnit.rig()`, `unrig()` on a move, `rigged()`); a location given back after its unit
  drew is recorded as drawn with nothing on it. `UnitDraw` judges a unit among the beats rigged in it
  and in every unit touching it, drawn or not. Nothing is drawn round a pick any more: the ground
  drawer (`WalkSiting.use_the_ground_drawer()`) and its give-up are deleted.
- **A mark rigs the next unit draw.** `UnitDraw.rig_the_next_draw()` puts a bag of the rows a mark
  rigs in front of the units' draws (a `MarbleBag` with no ordinary set, its marbles
  `MarbleDraw.Rigged`, an id and its row); `MarbleDraw.draw()` draws a row there first where the
  unit accepts it as it accepts its own marbles, taking its room, and leaves one it refuses in front
  for the next unit. `ResistanceDirector._rig_her_route_for()` rigs day 6's man shouting and day 7's
  van there (`ResistanceSteps.Step.rigs_the_next_draw`); day 11's mast still rigs her route's bag
  and is laid as a beat. `UnitDraw.drew_from_the_front()` says which plan came from the bag in front,
  and `EventsAhead` writes an `ahead` run-log line where it landed and how far from her.
- **Deleted, nothing reaching them:** the street-beat path of `WalkSiting` (`_on_her_street()`,
  `_could_be_in_her_view()`, `STREET_HALF_WIDTH`, the siting's day), `EventDef.is_met_on_her_street()`
  with `meet_on_her_street()` and its catalogue call, `SitedGround.is_a_wall_by_cost()`,
  `ResistanceSteps.TASK_CONTACT_WITHIN_THE_NEXT` and `VAN_WITHIN_THE_NEXT`.

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
- `tests/probes/calm_pelican_day7_van_met.gd`, twelve walks each of mark, task, calm and home: the
  rigged van drawn on 9 and the man on 11, **neither ever in her view**, each drawn 1,000 to 2,000px
  from her and her walk coming no nearer than 416 to 1,477px; on main the van was seen on 9 of 12
  and the man on 8. The board question named this cost ("met about as rarely as the far band
  measured").
- `tests/probes/placement_rows.gd` prints what it printed before the change, line for line.

**Departures from the written design, each open to Fable and the player.**

1. **Day 6's man shouting and day 7's van are no beats.** The design's Q1 had two answers, both
   laid by the siting; the player's answer is neither, and the build follows the orchestrator's
   reading of it: the next unit to draw stands them. So the street-beat path the design kept (its
   pick (b)) is deleted rather than kept, and so is the row flag it read.
2. **The rigged bag holds the rows alone.** `MarbleBag.rig()` fills a rigged bag of `x` with marbles
   taken from the bag being drawn from, but every unit draws from a bag of its own, so there is no
   one bag to take them from; the bag in front holds the ensured rows and nothing else, and the
   player's "the next draw (whenever that happens) will guarantee" is the next unit's. The other
   way: a bag of `x` filled with empty marbles, which puts him within the next `x` marbles of
   whichever units draw. The guarantee is no longer "within the next two events handed out on her
   route" (olive-koala 2's "in the next three events"), which the answer replaces.
3. **Which units may differ by her path is wider than the design said.** Its acceptance read
   "`differ` equals `beside-a-beat`", but a unit is judged among the draws of the touching units
   drawn before it, so a difference can carry along touching units, and a beat moved off a unit
   leaves what that unit drew round it as drawn (the design's 3.5). `WR` prints both: carried (none
   measured) and in or beside a unit a beat stood in, moved off or not.
   `tests/test_event_manager_units.gd` holds that no unit differs out of nowhere.
4. **What the design did not name:** `UnitDraw.drew_from_the_front()` and the run-log line; the
   siting treats a location no unit holds as drawn; `EventsAhead.rig_the_next_draw()` rigs nothing on
   a walk whose units do not draw as she walks, so a scene recipe's day 6 or 7 has no second man or
   van; the probe's walk is handed its unit draw, which it lacked, so a beat it laid was rigged in
   units nothing drew; the day 6 and day 7 suites walk on toward ground that has not drawn where
   their route ends first, since only a unit that draws can stand him; the events skill's own line
   that every unit's draw is the same whatever her path is narrowed besides its
   `plan-and-excitement.md` paragraph.

**Open to Fable and the player.** Whether "the next unit to draw" is the reading the player meant,
given that the rigged man and van are now drawn on most walks and seen on none of the probe's: the
other ways are the next unit to draw ahead of her on the branch she walks (the beats' rule, whose
far band the records sandy-magpie and olive-badger-2 measured at 1 and 0 walks of 12), or his old
place on her street just out of view (seen on 8 and 9 of 12).
