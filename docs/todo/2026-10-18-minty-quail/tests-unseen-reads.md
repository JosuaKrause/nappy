# Tests drive public seams: what the count cannot see

`tests-public-seams.md`'s two count commands cannot see a private member reached another way, a game
collection a test edits by hand, or a public member that only tests call. This item holds the rule
for those and what is left of them, by owner. Its rule for a seam is `tests-public-seams.md`'s: a
member made public, or added, has a caller among the game's own classes or is a dependency the
game's own code hands in, and where the game has no reader the test goes through what the game
exposes.

**Readings of the rule.** The first, open to the player's overturn, rests on the rule's wording and
leaves the DEV-only tier below unscheduled; the second and third are the player's; the fourth follows
from the rule alone:

- **A caller under `src/dev` counts as a game caller.** The rigs and the scene-recipe runtime are
  the composition root in `tools/layer_map.py`'s layering (**orchestrating**, "Code is designed by
  layer"), and `tests-public-seams.md` already accepts `Crowd.add_recipe_actor()` (only the recipe
  runtime calls it) as a seam. About 55 names stand on this reading.
- **A caller in the member's own class is no caller.** Told that about 250 public members are
  called only by their own class and the tests, the player asked "so basically they're not part of
  the API but tests use them to probe the state? so they're kind of a loophole", then answered "we
  should add the underscore", and of the pick that each becomes internal, its tests checking what
  the class does from outside, one staying public only where nothing outside can confirm the
  behavior, with its reason written down, "yes, that's cleaner" (curly-rabbit #1098). That pass is
  `tests-own-class-members.md`.
- **A member with no reader at all goes.** Asked whether such members go, the player: "delete them
  if possible. most cases should allow similar things via mocking the affected object. if it is
  absolutely not possible to get this information otherwise *and* this information is necessary for
  the test to make sense / confirm the desired behavior we can keep it. although those cases might
  be hints that the design of that module is suboptimal" (curly-rabbit #1095). **Read as:** each is
  tested through a fake handed in or through what the game exposes (the drawn arrow, the plans, the
  world) and then removed; one stays only where both conditions hold, and its builder writes down
  why and what about the module makes it so.
- **A hand-built checkpoint's facing and gate state go through a plan** (`Planned` with `facing`
  and `gate_state`, handed to `EventStreaming.add()`), not a new `spawn_extra()` parameter that only
  tests would pass.

**How a test writes game state.** Where the game has a callable writer the tests go through it: a
scar through `RunState.add_scar()`, a completed step through `RunState.complete_resistance_step()`
with the step's own `grants_progress`, a day's give-back through `ResistanceRunState.give_back()`,
a map's tile state through `close_streets()`, `seal_soft_tile()`, `clear_day_soft_seals()` and
`obstruct_tiles()` with `release_obstruction()`, events through `EventManager.spawn_extra()`,
`spawn_warned()` or a `Planned` handed to `EventStreaming.add()`, and an `EventWorld` through
`setup_world()`, `setup()`, `use_run()` and `use_player()`. What stays is fixture state on public
fields no game writer reaches alone:

- `run.attempt_spend.consumed_one_shots.append("burning_building")` (`test_day_loop.gd`): the
  scheduler appends it as it places the one-shot, and a test of the give-back needs it spent without
  planning a day.
- `run.resistance.sabotage_done = true` where the state the suite needs the run to be in is not
  what it tests, and playing the finale to reach it would be.
- `building.powered`, `day` and `condition` on a hand-built `Building.new()` or a sampled building
  (`test_blackout.gd`, `test_city_decay.gd`, `test_scenery_residency.gd`): the city writes them for
  every building at once, and these suites test what one building draws or does given its state.
- `test_invincible.gd` sets `noise` on its own fake world, a test double's state no game path sets,
  and `test_excitement_source.gd` hands a world its excitement sources, the hand-in `main.gd` and
  `City` make.
- `RouteTree.grow()` stays public for `test_power_station.gd`: the station day's corridor without
  its spur is one no day's own corridor gives. `test_blackout.gd` reads `_city.events.plans()`, which
  is public.

## 3. Public members only tests call (zero-reader list)

Method: a script lists every public `func`/`var` defined under `src/` whose name a test reads as
`.name` and that has no other word occurrence anywhere under `src/` outside comments and its own
definition (the "zero-reader list"). The script judged a member by its word and the list was
spot-checked by hand; `tools/check_test_only_members.py` reproduces the method, except that a name two classes
define is judged by its class where the reader's type is known. Verdict key: SEAM = a game caller exists or the game hands it in, so
converting is mechanical; GAP = the game has no reader, so the test goes through what the game
exposes (drawing, a signal, input and frames) or the member is removed or needs a design decision.

**Members only tests read that stay, each with its reason:**

- `Crowd.set_focus` (record minty-quail-lilac-walrus): the crowd's field follows the player only in
  the player half of its live tick, which also shoves, warns and strikes, while the rigs tick with
  `step()`, which has none; so a stroller handed through `use_player()` moves no field there, real
  frames would add bumps and strikes to every check, and recycling would drop the cars and walkers
  under test. **Open**, a change to `src/` and so a question first: hand the crowd a focus source, so
  that where the simulated patch stands is a game input apart from who she is, which would let
  `set_focus` go.
- `Telemetry.begin_memory_log` (`telemetry.gd`), read by `test_telemetry.gd` and about 30 other
  sites: it is the one way a test gets a live run log with no file on disk. Its reason is the design
  the player's answer points at (inbox #1095 in curly-rabbit): the autoload owns the log and where it
  lives, and only `RunSession` is handed its log, while the observer and the gameplay classes call
  the autoload by name, so a test cannot hand them a fake log. **Open:** handing the log to those
  classes, which would let it go.
- `EventsAhead.walk_siting` (record minty-quail-olive-sparrow): `test_route_bag.gd` reads the mast
  checks it sites, and `EventsAhead` builds that siting itself, so no test can hand it one.
  `EventLook.drawn_rect_now` (the same record): the caret is drawn straight onto the event and no
  recorder holds it.
- The balance helpers `Tuning.required_horn_time()`, `required_horn_sight()` and
  `sleepiness_gain_calm()` are functions of the tunables used to assert fairness contracts (the
  balance skill): a test reading a balance helper is the design.
- `walk_on_by_hand` (the dev runtime calls it, which counts as a game caller under the first
  reading), `ResistanceHappenings.cordon`, `ContactPoint.draws_a_mark`, `space_out_the_traffic`,
  `region_name_for` and `illustrated_path_for` (the bake calls them) and the rest of the list in
  `tools/test_only_members.txt` each carry their reason on their line.

**The two weaker tiers that no pass schedules.** The DEV-only readers (the only `src/` caller is
under `src/dev`, the scene-recipe and rig tools): about 55 names, among them `Crowd.add_recipe_actor`
and `recipe_coverage`, `City.set_region_plan`, `ResistanceDirector.read_mark`,
`start_recipe_task` and `scene_task_errors`, `EventManager.start_recipe`,
`EventScheduler.place_at` and `recipe_placement`, `EventInstance.walk_on_by_hand`,
`solid_part_centres`, `solid_part_shapes` and `is_solid`, `WorldMap.is_obstructed` and
`VisibleView.visible_share`. The first reading above counts `src/dev` among the game's own classes,
and the item's own seams `add_recipe_actor`, `place_at` and `read_mark` depend on it. The SELF-only
readers (public, the only caller the defining file itself) are `tests-own-class-members.md`'s.
