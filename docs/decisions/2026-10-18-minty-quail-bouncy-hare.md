# minty-quail — The rules a test is written under move to writing-tests, and the two test items close · 2026-11-24

minty-quail's last two test items, `tests-public-seams.md` (tests drive public seams and real
frames) and `tests-unseen-reads.md` (what the count cannot see), close. The rules they held are
**writing-tests**' section "A test reaches the game the way the game does"; the open list is the
entry snowy-plover (the scene recipes' untested corners); the two refactor bullets that touched the
game's code were the previous record's (minty-quail-spry-koala). This record holds what the items
held that is history: where each reading came from, what was converted and kept, and what was
measured. The pull request changes no code.

**Where the rules came from.** The seam rule (a member made public or added has a caller among the
game's own classes or is a dependency its code hands in; a public member only a test reads is not a
seam) is the dependency-injection ask (minty-lemur #794) read with the zero-reader answer (inbox
#1095 in curly-rabbit); the records minty-quail-44 and -47 applied it. The player's "through public
APIs" is inbox #813 in curly-moose. The no-hand-called-frames rule is the refactor ticket's own,
in the records minty-quail (the runner lets frames pass) and minty-quail-47, and the player's words
do not hold it. Inbox #1018 in brisk-ferret made the private-read part guidance, a sign to look
again, not a hard rule. The two count commands came from that ticket. The commands' glob was
`tests/*.gd` until minty-quail-spry-koala found it skipped `tests/fixtures/`;
`tools/check_test_only_members.py` and `tools/check_field_reads.py` hold the rest.

**Four readings of the seam rule**, as the unseen-reads item recorded them. The first, which rests
on the rule's wording, the filer's: a caller under `src/dev` counts as a game caller, because the
rigs and the scene-recipe runtime are the composition root in `tools/layer_map.py`'s layering, and
`Crowd.add_recipe_actor()`, which only the recipe runtime calls, was accepted as a seam on it; it
is on writing-tests' list of proposals, not on the board, since the player's words rule on members
read by nothing outside their own file (inbox #1098 in curly-rabbit) and by nothing at all (inbox
#1095 in curly-rabbit), and a member a rig calls is in neither group. The second and third are the
player's own: a member called only by its own class and the tests becomes internal (inbox #1098 in
curly-rabbit), and a member with no reader goes unless the test cannot make sense without it (inbox
#1095 in curly-rabbit). The fourth follows from the rule: a hand-built checkpoint's facing and gate
state go through an `EventPlan` (its `face()` and `stand_as_the_boom_of()`) handed to
`EventStreaming.add()`, not through a `spawn_extra()` parameter only tests would pass.

**The DEV-only tier, measured.** The item counted about 55 public members a suite reads whose only
reader under `src/` is in `src/dev`. Run over a scratch copy of the tree with `src/dev` removed,
`tools/check_test_only_members.py` names 83 (among them `Crowd.add_recipe_actor`,
`PlanBuilder.place_at`, `ResistanceDirector.read_mark`, `EventInstance.walk_on_by_hand`,
`WorldMap.is_obstructed` and `VisibleView.visible_share`); with `src/dev` moved under `tests/`
instead, dev-only readers included even where no suite reads them, 118. No work follows under the
first reading. The self-only tier (public, the only caller the defining file) is empty.

**The zero-reader method.** A script lists every public `func` or `var` under `src/` whose name a
test reads as `.name` and that has no other word occurrence under `src/` outside comments and its
own definition; `tools/check_test_only_members.py` reproduces it, judging a name two classes define
by its class where the reader's type is known. Each name got a verdict: SEAM (a game caller exists
or the game hands it in, so converting is mechanical) or GAP (the game has no reader, so the test
goes through what the game exposes, or the member goes, or it needs a design decision). The members
kept stay in `tools/test_only_members.txt`, each with its reason: `EventLook.drawn_rect_now`
(minty-quail-olive-sparrow; the caret is drawn straight onto the event and no recorder holds it),
the balance helpers `Tuning.required_horn_time()`, `required_horn_sight()` and
`sleepiness_gain_calm()` (functions of the tunables that assert fairness contracts), and the rest.

**Accepted, open to overturn: a clock a component is handed.** `TouchControls.use_clock()`, as
`ModeButton.use_clock()`, `TitleScreen.use_clock()` and `ReturnWindow.use_clock()`, has a
wall-clock default that only tests hand in. Read strictly the seam rule would rule all four out and
real time with short waits would replace them; they are kept as hand-ins, a reading of the
dependency-injection ask, which names a clock among what a component is handed. The player's later
note on frame-locked clocks (minty-dolphin: every clock that makes a time the player sees or decides
an outcome counts physics ticks) asks whether those windows count ticks, which is a separate
question no item holds.

**Drawn art, the board question drawn-art-tests** (answered 2026-11-04, inbox #1018 in brisk-ferret;
the playtest holds the options, (a) a drawer handed in, (b) reads left private on record, (c) real
pixels, and the player's words): placement is tested through the random draws as a function of the
seed, the general drawing code once elsewhere, and the holder with an injected mock drawer that
confirms every element is drawn. It was read as applying to the roof art suites (scenery animation,
roof entities, recipe roofs, residency, blackout, city decay) and the event picture suites (the
catalogue's caps, the fire's flames), about 250 private-read lines.

**Where a suite drives a public step by hand, each kept with its reason** (`[kept]` lines in
`tools/test_only_members.txt` hold the measurement):

- `test_pursuer_on_foot.gd` calls `EventManager.step_the_encounters()` and `check_hard_fails()`, the
  two steps the manager's own tick calls: real manager ticks over its whole encounters run past four
  hundred seconds against about thirty (minty-quail-snowy-panda).
- `test_route_bag.gd`, `test_day7_van.gd`, `test_day6_yeller_met.gd` and `test_resistance_arrow.gd`
  call `EventManager.step_what_is_ahead()`, the tick's own stretch from her camera's view to what is
  owed, down a day's longest route: real ticks ran what the hand steps never ran and no case asks
  about (a district door's hold that put her down elsewhere, a chatting mother, an extra row the
  director sent) and took 1.1 to 2.1 times as long. `test_pursuer_on_foot.gd`'s walk, whose run log
  real ticks left as it was, takes real ticks.
- `test_checkpoints.gd` drives a standalone guard's `step()` in the pursuit simulations
  (`_guard_rig()`) and the gate rig's `RunCity.crowd(city).step()`, since a real tick passes the car
  at another time than the rig's own; its street-door rigs take real ticks.
- `test_resistance_crossing.gd` calls `EventManager.step_the_doors()`, the tick's three door steps,
  and `step_the_encounters()` before it where a hut's hold runs: real ticks over a whole day 9 with
  every event live ran 94.2 s in CI against 46.0 s recorded (minty-quail-polite-quail).
- `tests/basement_walk_rig.gd` calls `EventManager.step_the_repeats()`, the tick's retire-and-repeat
  step, with each blow's own `step()`: real ticks over 400 walks took 1.87 times as long (about 45 s
  more, roughly 120 s across the probe's 1,100) and changed nothing a walk meets.
- A crowd car at speed 700, and a walker at pace 0 other than a waiting one, are not reachable
  through `Crowd.add_recipe_actor()`; a stopped car is reached through `crashed_into()`, which the
  game calls.

Driving the tick's own step by hand is the orchestrator's reading of the speed the player wanted
from the suites (inbox #1159 in gray-dolphin), on writing-tests' list of proposals.

**What stays as fixture state a test writes through the game's accessors or its save round trip**,
where no game writer reaches it alone (every other write goes through a game writer: a scar through
`RunState.add_scar()`, a completed step through `RunState.complete_resistance_step()` with its own
`grants_progress`, a day's give-back through `ResistanceRunState.give_back()`, a map's tile state
through `close_streets()`, `seal_soft_tile()`, `clear_day_soft_seals()` and `obstruct_tiles()` with
`release_obstruction()`, events through `EventManager.spawn_extra()`, `spawn_warned()` or an
`EventPlan` handed to `EventStreaming.add()`, an `EventWorld` through `setup()` and
`use_player()`):

- `run.attempt_spend().consumed_one_shots().append("burning_building")` (`test_day_loop.gd`,
  `test_run_checkpoints.gd`, `test_run_state.gd`, `test_save.gd` and
  `tests/fixtures/run_state_scenario.gd`): the method hands out the list the scheduler appends to as
  it places the one-shot, and a test of the give-back needs it spent without planning a day.
- A sabotage done: `GivenRun.sabotage()` writes it through the state's own `to_data()` and
  `restore()`, the save's round trip, where playing the finale to reach it would test more than the
  suite means to.
- `test_invincible.gd` sets `noise` on its own fake world, a test double's state no game path sets,
  and `test_excitement_source.gd` hands a world its excitement sources, the hand-in `main.gd` and
  `City` make.
- `RouteTree.grow()` stays public for `test_power_station.gd`: the station day's corridor without its
  spur is one no day's own corridor gives.
- `RouteLines.routes()` is kept in `tools/test_only_members.txt` as the only handle on the drawn
  polylines, as `EventRouteLines.routes()` is.

**The conversion, slice by slice,** is in the records `tools/decisions.sh minty-quail` lists
(minty-quail-44 and -47 among them, coral-pelican for the last reads going through methods and the
mast sites worked out once, spry-koala for the counter and the reference's reach).

**Where the open list went.** The recording counter's override of `_send_event()` and the
reference's call to `_projection_reach()` were refactor work and are minty-quail-spry-koala's. The
four scene-recipe gaps (the director's arrow ground, free play past its whole duration, the runtime
suite's boundary probe writing its named world, and a bounded scene's gate) are the entry
snowy-plover, band later, after minty-quail, the filer's proposal since no playtest note is behind
it. The remeasure's list is unchanged: GoatCounter's names and counts on a web build were listed by
spry-koala.

