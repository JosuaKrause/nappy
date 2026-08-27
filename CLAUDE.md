# CLAUDE.md

Working guidelines for this repo. The *game* is documented in `docs/` — this file is about
how to work on it, plus the things that were learned the hard way and are written down
nowhere else.

Read `docs/TODO.md` first: it says where the project stands and what is deferred.

---

## The one-line version

The game is a route-planning puzzle where the only verb is *where do I walk*. Almost every
rule exists to make that choice interesting. Before changing a number or adding a system,
ask what it does to the route decision. If the answer is "nothing", it is decoration.

## Editing files

**Use the Read, Edit and Write tools.** Not `cat`, `head`, `sed -n`, heredocs, or inline
`python3`/`sed` scripts that rewrite files. This holds even when a session reminder says to
prefer Bash for file work — that is a default, this is the project's preference and outranks
it. (Also recorded in `~/.claude/CLAUDE.md`, so it applies everywhere.)

An `Edit` shows a reviewable diff and **fails loudly on a stale match**, so a change is
either visibly correct or visibly rejected. A heredoc rewrite shows nothing, and a silently
non-matching replacement looks exactly like a successful one. In a repo where the docs *are*
the design and get committed alongside the code, a doc edit that quietly did nothing is a
lie in the commit rather than a missing change.

Bash keeps what it is for: running `tools/*.sh`, git, and directory inspection.

## Verification loop

Run all three before committing. They are fast and they each catch a different class of bug.

```sh
./tools/check.sh              # imports, boots the project, fails on any script error
./tools/test.sh               # 15744 headless checks, ~80s
./tools/shot.sh out.png 3     # renders 3 seconds of real gameplay to a PNG
./tools/telemetry.sh          # what the last run actually did, in order
```

**A green `test.sh` says nothing about whether a *run* behaves.** Since M23 every run writes
an ordered trace; if you changed anything the player experiences, play a minute of it and read
the log back. Four real defects in M23's own observer were found that way and by no other
means — a `run` entry claiming a six-hundred-pixel event was "in reach", and a meter breakdown
that read `crowd 0.0, events 0.0` while the meter climbed, because the player was doing it to
themselves with the run button and nothing said so.

**Where a run cannot be played, walk a rig and read the meter.** M19's collision passed a
green suite and a screenshot and was still badly wrong: a pedestrian slower than the player
was ploughed along the pavement in front of her, permanently in contact, permanently loud, at
150 excitement per second. It took forty seconds of a scripted walk down a real pavement to
see it, and nothing cheaper would have. A throwaway `tests/test_zz_*.gd` that prints numbers
and is deleted before committing is the headless stand-in for the minute of play the rule
above asks for — and the numbers it prints are how a balance constant gets set, rather than
derived. Two things it found that no amount of arithmetic would have: that one, and that a
contact radius of 18px leaves **no line to walk** on a two-tile pavement.

**A green `check.sh` says nothing about whether the game looks right** — headless runs never
call `_draw()`. Several real bugs in this project were found only by opening a screenshot:
building extrusions overhanging every sidewalk, zebra crossings rendering as visual static,
a fire always spawning against the map wall. If you touched anything visual, take a shot and
actually look at it.

**Since M27 a screenshot of a standing player is a screenshot of almost nothing.** The crowd
and the events are built around her, and the director only puts something in front of her while
she is going somewhere — so use `--walk north|south|east|west`, which holds a direction down for
the whole run. `tools/shot.sh` forwards every dev flag now; it silently dropped them until M22,
and a shot taken to look at one specific event was of the doorstep instead.

**Where a cue cannot be triggered on demand, relax its condition, look, and put it back.** The
screen-edge badge needs something lethal off-screen and closing, which is not something a
six-second screenshot can be asked for. Forcing it on for one shot found three things no test
could: the badge collided with the excitement meter, the icon was squashed by a square box, and
two of the three had no silhouette in them at all.

`--after` on the screenshot tools is in **seconds**, not frames. It counted frames once,
which was quietly useless: the windowed build draws ~110fps, so "wait 240 frames" for a 2.6s
telegraph still caught it mid-telegraph and looked like a broken telegraph.

## Git workflow

- **One branch per milestone**, named `feature/<thing>`, merged to `main` with `--no-ff`.
  The merge commits are the project's spine; keep them.
- **Commit the docs in the same commit as the code.** `docs/` is not a report written
  afterwards, it is the design. If an implementation contradicts a doc, the doc is wrong and
  gets fixed in that commit.
- Commit messages explain **why**, and say what was tried and rejected. When something was
  discovered mid-implementation ("the first version parked every route against the city
  wall"), say so — that is the part that is not recoverable from the diff.
- Never commit `.godot/`. It is gitignored, which means a fresh clone has no `class_name`
  registry and every typed reference fails to parse until `check.sh` runs the import pass.

---

## Godot 4.7 / GDScript gotchas

These all cost real time here. They are not obvious and the engine does not warn about most
of them.

**`set(key, value)` silently drops a type mismatch.** Building the resistance step table
from a Dictionary via `set()` dropped every `Array[int]` field, leaving three of six steps
with nowhere to go and *no error anywhere*. Never build typed objects from dictionaries. Use
an explicit factory function with named parameters.

**Passing an untyped `Array` into an `Array[T]` parameter leaks at shutdown.** The coercion
at the call boundary retains the arguments; you get "N ObjectDB instances were leaked at
exit". Declare the real element type at the call site. `tests/test_acts.gd` carries a note.

**Some warnings are errors by default.** `var x := some_variant` ("the variable type is
being inferred from a Variant value") fails the parse outright. Annotate the type instead:
`var x: int = ...`. This does not show up until the project actually boots, which is why
`check.sh` exists.

**A runtime error inside a test suite hangs the runner instead of failing it.**
`run_tests.gd` calls each suite's `run()` synchronously and then `get_tree().quit()`. An
error — a null `by_id()` result, say — aborts `_ready()` before the quit, so the headless
process sits there forever printing nothing. A test run with *no output at all* means an
error in a suite, not a slow suite.

**`--script` skips autoloads.** The test suite runs as a *scene*
(`godot --headless --path . res://tests/tests.tscn`) because every test needs `Tuning`.

**An autoload name cannot also be a `class_name`.** That is why shared enums live in
`src/game_enums.gd` rather than on `GameState`.

**`SomeNode.new()` does not get the name `SomeNode`.** `Camera2D.new()` is named
`@Camera2D@41`, so a `@onready var _camera := $Camera2D` in a test rig silently fails. Set
`.name` explicitly when a node is looked up by path.

**A cross-script enum is not the same type as itself.** `static func f(side: Side)` in one
script, called from another as `f(x)` where `x` came from `OtherScript.Side`, fails to parse:
*"argument 2 should be Side but is StreetNetwork.Side"*. Widen the parameter to `int` and say
why in a comment. `StreetNetwork.beside_block()` is the one place that does.

**Nodes are not refcounted.** A test double extending a `Node` class (e.g. a fake
`EventManager`) must be `free()`d by hand or it leaks. `RefCounted` doubles do not.

**A negative-width `Rect2` does not flip `draw_texture_rect`.** It gets normalised on the
way through, so the sprite lands a full width to one side — which looks like art sliding off
its own shadow, not like a failed flip. Mirror with `draw_set_transform(at, 0, Vector2(-1,
1))` around the anchor instead. `Sprites.draw_standing()` is the one place that does it.

**`process_mode` is inherited, so one `PROCESS_MODE_ALWAYS` exempts a whole subtree.**
`main.gd` sets it on itself so Esc still quits while the summary has the tree paused — and
every descendant defaults to `PROCESS_MODE_INHERIT`, so the city, the player, the crowd, the
events and the resistance deadline all inherited the exemption. `get_tree().paused = true` ran
for six milestones and paused nothing: the player kept walking behind the screen that said the
day was over. The fix is `main._pauses_with_the_game()`, called on every node that is the game
rather than the frame around it. **If you add a node under `Main`, it needs that call**, and
nothing warns you.

**`_draw()` is retained.** It re-runs only on `queue_redraw()`, so an expensive one-off draw
(the 10k-tile city ground) is fine, but anything animated must call `queue_redraw()` itself.

**`move_and_slide()` owns `velocity`, so do not put anything else in it.** M19's collision
deflects the player, and folding the deflection into `velocity` before the slide meant
`is_idle()` and `run_excess_ratio()` — the only two questions the baby asks the rig — started
answering for the crowd rather than for the player. Restoring `velocity` afterwards is worse:
it throws away the slide's own correction, so walking into a wall stops reading as idle and
starts making sleep progress. A second displacement goes through its own
`move_and_collide()`, which respects walls and touches nothing.

---

## Code style

Match what is already there rather than importing habits from elsewhere.

- Tabs for indentation. Wrap at ~96 columns.
- `##` doc comments on every class and on any function whose purpose is not obvious from its
  name. Class doc comments say what the thing is *for*, not what it contains.
- Section dividers inside longer files:
  `# ---------------------------------------------------------------- drawing ---`
- **Comments explain why, never what.** `# Skip the stretch inside an intersection, where a
  centre line makes no sense.` is worth writing; `# loop over tiles` is not. Where a value
  was tuned against something, say what: `# Sized so it dominates the middle of a park but
  leaves the far side genuinely calm.`
- Leading underscore for private members and methods. Godot lifecycle methods (`_ready`,
  `_draw`, `_process`) are the exception and are not private.
- Prefer a named constant in `Tuning` over a literal anywhere gameplay can feel it.

---

## Invariants — do not break these without a deliberate decision

**Determinism.** Nothing gameplay-relevant may call the global `randi()`/`randf()`. Use
`GameState.city_rng()` (layout, once per run) or `GameState.day_rng(day, stream)` (per day).
Pass a distinct `stream` per consumer or two systems asking for "the day's RNG" start from
the same seed and their first rolls move together. Purely cosmetic randomness may use the
global RNG and must stay away from anything touching the meters.

**Excitement is a pure query.** Events never push a value at the baby. `Baby` asks the
`WorldContext` for the total at its position, and the world sums `contribution_at()` over
live instances. This is why events compose by simple addition, there is no ordering to get
wrong, and an event can be tested without a scene. Do not add a code path that writes to
`Baby.excitement` from outside. The crowd (M13) is summed the same way and for the same
reason — `City.total_excitement_at` adds the two and nothing else.

M19's collision was the first thing that ever wanted to push, and the way it does not is
worth copying: **a contact startles the person she walked into.** The jolt is a decaying
source on that agent's own `contribution_at()`, so a bump is summed exactly like the body it
came from, `City.total_excitement_at` still adds two terms, and a crowded pavement composes
by addition like everything else. Anything else that wants to "add excitement" should find a
body to put it on rather than a third summand — and if there genuinely is no body, that is a
design conversation, not a plumbing one.

**Sampling a tile grid by stepping world points aliases, and it aliases where it matters.**
*(M29.)* `CrowdAgent`'s crossing scan probed `position + forward * step * TILE_SIZE`, which is
correct almost everywhere and wrong at exactly one place: a car stopped at the stop line is a
few pixels from the paint, so both neighbouring samples miss the zebra, the car decides there is
nothing to give way to, and pulls away with somebody standing on it. Walk the **tiles** —
`world_to_tile` once, then integer steps — whenever the question is about tile types rather than
about distance. Start at step zero, too: the car's own tile is the difference between "not there
yet" and "already across".

**Separation between bodies is positional, never a force.** *(M19 for the player, M27 for the
traffic.)* A brake, a repulsion, a steering weight — all of them keep a gap that already exists
and none of them can open one that does not, so two bodies that start inside each other stay
there. `Crowd._bump()` resolves the player against a pedestrian by moving both; `Crowd.
space_out_the_traffic()` resolves a lane of cars from the front backwards. M27's first version
was a headway brake alone, and it left eight overlapping pairs a frame on the arterial, because
a car recycled into a lane lands at a point it cannot see. If a new pair of things must not be
inside each other, move them apart; do not ask them to want to be apart.

**The noise floor is emergent, never a constant.** A street is loud because there are
people and cars on it, which the player can see. There used to be an invisible ambient band
on the arterials doing that job; it was replaced, not supplemented. If you find yourself
adding a city-wide "background noise" number, that is the thing this rule exists to stop.

**`Baby` knows nothing about tiles or events.** Its entire interface to the world is three
questions: `is_calm_zone`, `is_alley`, `total_excitement_at`. Adding an event type must never
require touching the meters.

**The lattice is fixed; what a block *is* is not.** *(M15 replaced the old "the `CityMap`
is immutable for the run" rule with this one.)* The street lattice, the block boundaries,
the carves and the building footprints are all fixed for the run. What may change is a
block's **purpose** — a park can be requisitioned, a commercial street can go dark, a
residential block can burn — and only ever along the arc `CityGenerator` planned for it up
front. The geometry the player learns stays true; the meaning of it does not.

The hard part of that rule is the half that is still absolute: **no purpose change may move
a walkable tile.** `tests/test_blocks.gd` pushes every block to the end of its arc across 40
seeds and asserts the walkable set is identical tile for tile. Per-day *closures* remain
events with an `obstructs_radius`, not tile edits.

**The day is planned across the whole city; only the world near the player is built.** *(M27,
and the licence is playtest 04's own: "consistency is not that important, nobody can run after
cars anyway to confirm they are still there off screen.")* Every guarantee the game makes is
stated over a **day** — one usable park, two distinct routes to two distinct calm areas, a
one-shot that fires once per run, determinism from a seed — and all of them are properties of
the *plan*. `EventScheduler.build_day()` therefore still plans the entire map at dawn. What
streams is the *instantiation*: a plan becomes a node when the player is within
`EVENT_STREAM_RADIUS` and stops being one when she leaves.

Three things that keep it honest, and each is a way it could quietly stop being legal:

- **Nothing may be seen to appear.** Both radii are wider than half the viewport diagonal.
- **`EVENT_STREAM_RADIUS` must stay wider than the widest field in the catalogue**, so an event
  is outside its own outer radius the instant it becomes visible. Otherwise streaming is a way
  of dropping events on people, and the telegraph contract below is a lie.
  `tests/test_event_manager.gd` asserts it against the catalogue.
- **A spent plan stays spent.** Streaming may take a *running* event away and give it back; it
  may never rewind one that has finished, and the bookkeeping an event does once — a scar, a
  block arc — happens on its first instantiation and never again.

Do not move a guarantee out of `build_day` and into the streaming. If something has to be true
of a day, it has to be decided where the day is.

**The telegraph fairness contract.** A player who starts walking away the instant an event
becomes visible must get clear before it hurts. `Tuning.validate_event()` asserts it on load
and `tests/test_events.gd` checks the whole catalogue. A violation is a bug, not a difficulty
setting. Two documented exemptions: `AMBIENT` events (they never "appear") and `city_wide`
ones (no edge to walk out of).

M27 added a third way in and it is *not* an exemption: an `AHEAD_OF_PLAYER` event has no
telegraph phase the player can see coming, so the contract is paid in geometry instead. It is
sited far enough ahead that she is outside its outer radius for the whole telegraph, and
`EventDef.validate()` refuses one that obstructs, because nothing checks a route around a thing
with no tile.

M28 added a fourth thing, and it is not an exemption either: **the contract is stated per event
and the player experiences the sum.** At one event per block the outer radii overlap, so walking
out of one field can mean walking into another — which is the density working, right up until
the field she walks into is one of the three that end the day. So **nothing else happens inside
a lethal event's field**: a `hard_fail` event keeps its whole `outer_radius` clear of every
other event at placement, and it is the one spacing rule with no fallback — an abduction that
cannot find room is not placed. `EventScheduler._room_around()` enforces it, `tests/test_events.gd`
asserts it over a whole run. If a new event ever becomes lethal, it inherits this, not just the
telegraph.

**The traffic fairness contract.** *(M19.)* A car is lethal and is **not** an event, so
`validate_event()` never sees it. `Tuning.validate_traffic()` is its equivalent and runs on
boot. Two things stand in for the telegraph: the painted carriageway, which is permanent and
learnable and which she chooses to step onto, and the horn, which must be long enough to walk
the whole width of it with the doubled hard-fail margin. If anything else in the game ever
becomes lethal without being in the catalogue, it needs its own stated contract in the same
place — a hard fail with no written contract is a bug waiting to be called a difficulty
setting.

**Every day stays winnable, and winnable more than one way.** The scheduler guarantees at
least one unspoiled park and a walkable route from home to a park. Since M16 the day carries
a stronger guarantee on top of it: **at least two distinct routes to at least two distinct
calm areas**, where distinct means sharing no street. `ClosurePlanner` checks it before
accepting each closure rather than repairing the day afterwards, so a bad set never exists
even briefly. Anything new that closes a street must go through it — `tests/test_routes.gd`
will fail the build if it does not.

Two exemptions, and they are the same exemption at both ends of the journey: **a doorway is
not a route.** The street outside the home is never closed (the home is a notch with one
exit), and an area is reached by arriving at *either end* of a street it opens onto, so a
courtyard with one archway can still have two routes to it.

**A closure is silent, and it is the only thing that moves where the player may walk.**
Closures change the shape of the route and contribute nothing to the meter — the noise of a
street is the crowd, the danger is the events, the shape is the closures. A noisy roadworks
already exists as the `construction` event. Do not let a closure emit; it would be a third
thing for `City.total_excitement_at` to sum, and that list is exactly two long on purpose.

**No circles around entities.** *(Standing decision, playtest 02 finding 8, restated by
playtest 04 finding 2. The aura rings were **deleted** in M22, not restyled. Do not add another
one, and do not reach for a ring when something new needs signalling.)*

> How dangerous a thing is has to be visible from looking at **the thing**.

A ring communicates a falloff radius, which is a number. A silhouette communicates a threat.
The vocabulary that replaced it, in `docs/EVENTS.md`, "The visual vocabulary": the **entity
itself** carries most of it; a **caret above the entity** for danger that *changes over time*
and nothing else; a **badge at the screen edge** whenever something lethal or faster than a
walk is off-screen and closing, carrying its own silhouette so it says what is coming rather
than that something is; and above the **player** a flashing exclamation mark for a
soon-to-be-bad spot, doubled and red for danger already on her. Nothing draws a field.

Two rules that are easy to lose and are the whole reason it is better than the rings:

- **A cue that marks everything says nothing.** The rings marked a notice board exactly as hard
  as an abduction, which is most of why they explained nothing. The caret is for *lethal,
  telegraphing, pulsing or swelling* — a barricade and a burnt-out shell are visibly what they
  are and get none. A first pass used "louder than the walking decay" and marked all of them,
  which is the ring's own mistake in a new shape. `tests/test_danger.gd` holds the line, and it
  also asserts that the whole catalogue is never marked at once.
- **The mark breathes**, tracking current emission, which is the one thing the ring did that a
  discrete symbol does not get for free. Without it a pulsing event stops being something to
  time a pass through and becomes something that hurts at random.

The exclamation mark is the load-bearing one. Every other cue says *a thing exists*; that one
says **the fairness contract is now about you and the clock has started**, which is the
difference between information and instruction. `Stroller.warn()` is additive rather than a
setter for a reason: the crowd and the events both watch the ground she is standing on in the
same frame, and a setter lets whichever runs second clear what the first just said.

**Telemetry never touches gameplay.** *(M23.)* No RNG, no `day_rng()` stream, nothing that
changes a placement or a roll. Where a system logs a random outcome it hoists the **existing**
roll into a variable to print it; it never adds one. That hoist is a one-line edit with a way
to be catastrophically wrong — consume one extra value from a day's RNG and every event placed
after it moves, and the determinism invariant above takes every other guarantee down with it.
`tests/test_telemetry.gd` plans all fourteen days with the log off and again with it on and
requires the plans to be identical event for event.

The corollary: anything needing a per-frame check goes in `TelemetryObserver`, not in the
gameplay class. The telemetry stays out of the files that decide things, which is what makes
the rule easy to keep. See docs/TELEMETRY.md.

**Audio is never the only channel.** Every cue that will eventually be audio must also exist
visually, and the visual must be sufficient on its own — the game has to play identically
with the sound off. Build the visual first and judge it alone; audio is added afterwards as
redundancy. An event whose telegraph only works "because you hear it coming" is unfinished,
and the fairness contract cannot catch it: `validate_event()` checks the geometry, not
whether the player was actually warned. See docs/EVENTS.md, "Showing the danger", for the
visual vocabulary and the two places it is currently incomplete.

---

## Recipes

**Change the event density** — `max_per_day` in the catalogue **first**, then
`EventScheduler.budget_for()`, because a budget the catalogue cannot spend is not density. M28
is the case that proves it: the day-1 pool's caps summed to 18, so raising the budget to a
hundred placed the same thirteen events. Then **measure what a day places**, over several
seeds, since `_ensure_one_usable_park` strips whatever reaches the calmest block and
`_ensure_the_city_is_still_walkable` drops obstructions that would seal the city. Do not derive
the number; a temporary probe suite that prints per-day counts takes two minutes and is the
only honest way to set it. Measure four things and not one: **placed per day**, **live inside
`EVENT_STREAM_RADIUS`**, **on screen at once**, and **met on a route** — they moved by
different multiples in M28, and only the last one is what the player is complaining about.

**Add an event** — `src/events/event_catalogue.gd` only, in the act's section, plus a line in
the `docs/EVENTS.md` table. Everything else is data-driven. If it needs behaviour no field
covers, add the field to `EventDef` and handle it in `EventInstance` — resist adding a script
per event. `tests/test_events.gd` will fail the build if the geometry is unfair.

Decide `spawn_mode` deliberately. `MAP` is the default and is right for anything the player
could plan around: it is a place, and finding out it is there is what walking a street is for.
`AHEAD_OF_PLAYER` is for the small number whose entire content is *the moment it happens to
you* — three seconds of cat is not a place — and it may not obstruct.

**Change the crowd density** — `Tuning.CROWD_PEDESTRIANS_PER_ACT` / `CROWD_CARS_PER_ACT`, which
since M27 are populations of the **field** rather than of the city, and
`CrowdLanes.ARTERIAL_BUSYNESS`, which is one street's share of the three or four corridors in
the box rather than of sixteen. Then **measure it**, with a throwaway probe over a minute of a
real day: how often there is a safe gap to cross the arterial and an ordinary street, the mean
wait at the kerb, contacts in a forty-second walk down a lane centre *and* holding the midline
between two lanes, and whether any two cars share a lane closer than a car's length. The table
in `docs/PLAYTEST-04.md` is what those came out as, and re-measuring is the only honest way to
move them: a lane has a **capacity**, and past it the arterial jams solid and no controller
helps.

**Change a balance number** — `src/autoload/tuning.gd`, which is the only place they live.
Expect tests to push back: several encode *relationships*, not values (traffic noise must stay
under the walking decay; a fast mover must telegraph across its whole radius). If a test
fails, decide whether the relationship or the number is wrong — do not just update the test.

**Add a tile type** — `GameEnums.TileType`, then `src/city/tile.gd` (walkable / calm / alley /
road / colour), then an SVG in `assets/tiles/`, then `assets/ground_tileset.tres` **and**
`src/city/ground_tiles.gd` in the same order (the source ids are positional and mirrored by
hand), then wherever the generator should emit it.

**Add a block purpose** — `GameEnums.BlockPurpose`, the ground it puts down in
`CityMap.open_tile_for`, `Tile.is_calm` if it is calm ground, and the arcs that may reach it
in `CityGenerator._plan_arcs`. If it is calm, check `MIN_CALM_BLOCKS_AT_END` still holds —
`validate()` will tell you, on every seed, if it does not.

**Add a closure kind** — `RoadClosure.Kind`, a row in `RoadClosure.KINDS` (name, first day,
weight), an SVG in `assets/closures/`, and a line in `ClosureMarker.CAUSES` — unless it has
nothing to leave in the road, like `CORDON`, in which case the barriers are the whole of it.
Nothing else: the kinds differ in look and timing only, because a street you cannot walk down
is a street you cannot walk down.

**Add a resistance step** — `src/resistance/resistance_steps.gd`, via the `_step()` factory.

**Add a HUD element** — `scenes/ui/hud.tscn` plus `src/ui/hud.gd`. The HUD listens to
`EventBus` and holds no reference to the world. Anything that has to *ask the world* where
things are every frame does not belong in it: `DangerEdge` is its own layer, created by `main`,
for exactly that reason.

**Add a danger cue** — first read `docs/EVENTS.md`, "The visual vocabulary", and pick a row
that already exists. The vocabulary is deliberately short and adding to it is a design
decision, not a drawing one. Never a ring; see the standing decision above.

**Add a telemetry entry** — `Telemetry.note("kind", "sentence")` where the thing happens, a
row in the table in `docs/TELEMETRY.md`, and a kind reused from that table rather than a
synonym for one. It has to answer a question that is open in `docs/TODO.md` or a playtest doc;
if it does not, it is a metric and does not belong. Anything per-frame goes in
`TelemetryObserver`. Read a run back with `./tools/telemetry.sh`.

---

## Testing policy

Test what a screenshot cannot see, and screenshot what a test cannot judge.

- **Always tested:** meter arithmetic, falloff and the fairness contract, generator
  guarantees across many seeds, scheduler determinism, day outcomes, ending selection. These
  are the places where a bug is invisible until it ruins somebody's run.
- **Integration-tested against a real `City`:** anything about wiring — retirement,
  successors, scars. `tests/test_event_manager.gd` exists because a freed-node-left-in-a-list
  bug is invisible to a data-level test, and that bug happened.
- **`tests/test_full_run.gd`** plays three seeds through all 14 days with time actually
  advancing. Keep it that way: an earlier version only *planned* each day, so the mobile
  one-shots never finished and the whole successor-and-scar chain went untested while the
  test passed.
- **Not tested, checked by eye:** layout, colour, readability, whether an aura is legible
  from across a street.
- A test asserting a *relationship* beats one asserting a value. `intensity < walking decay`
  survives rebalancing; `intensity == 3.2` does not.
- The suite must exit clean. Leak warnings at shutdown mean a real retain bug — see the
  gotchas above.

---

## Things deliberately not done

Do not "fix" these without a reason; each was a decision.

- **Closures are checked before they are accepted, not repaired afterwards.** The obvious
  shape — place N closures, then drop them until the day is legal — has an order-dependent
  answer and a window where the day is illegal. Testing each candidate against the invariant
  before accepting it is the same cost and has neither problem.
- **Counting distinct routes is a max flow, not a search for routes.** Two edge-disjoint
  paths is what "two distinct routes" means, and by Menger's theorem it is also "no single
  street cuts this off". Two BFS augmentations on a 64-node graph, not a flood fill over ten
  thousand tiles — which is why it can run on every candidate closure, every day.
- **No spatial hash for events.** The budget tops out near 22 concurrent events. A linear
  scan is free and a hash is more code with more ways to be subtly wrong.
- **No `impulse` field on events.** A sharp spike is a short `duration` at high `intensity`,
  which keeps the excitement model a pure query.
- **Events are defined in code, not `.tres`.** Reviewable in a diff, validated on load,
  assertable as a whole catalogue in a test.
- **No quest log or marker for the resistance.** It is a chalk mark on an alley wall and one
  terse HUD line. This is a deliberate risk: a player may finish a run never knowing the good
  ending existed. `docs/TODO.md` lists it as an open question for playtesting.
- **The home's doorstep is exempt from the route-redundancy guarantee.** The home is a notch
  with one exit, so sealing that street seals the player in. It is a constraint on where
  Act IV may barricade, not a layout flaw.

---

## Two measured facts about the catalogue

Both came out of playtest 02. The full table is in `docs/EVENTS.md`, "What an event actually
costs" — regenerate it whenever a rate in `Tuning` moves, because it is the fastest way to see
what a balance change did to the whole catalogue.

- **Walking through an event used to be nearly free before act III**, and M19 fixed the worst
  of it rather than all of it. `dog_walker` cost −0.1 points to walk straight through the
  centre of, so ploughing into it beat going round; it is +21.6 now, `cafe_tables` blocks a
  pavement from day 1, and the street costs something on its own. Act II is still gentle and
  still open. Three rows stay negative on purpose — `poster_crew`, `barricade` and
  `burnt_shell` are scenery, not obstacles — and `tests/test_events.gd` names exactly those
  three as the exemptions, so a **fourth** negative event has to be a decision somebody takes
  rather than a number nobody checked.
- **Running is the wrong move against every event in the game.** Unchanged by M19.
  `EXCITEMENT_FROM_RUNNING` plus the collapsed decay (3.5/s → 0.5/s) beats the shorter
  exposure every time. The run button is a trap. Making running *necessary* (M25) is therefore
  a mechanic to build — something that pursues, a lethal radius that grows, a window that
  shuts — not a constant to tune, and its fairness contract has to be stated over `RUN_SPEED`.

**And one fact the table does not cover.** Since M19 the cost of a route is no longer only the
events on it: a contact with a pedestrian is ~15.6 points and a car's horn ~8, and neither is
in the catalogue. A balance argument that reaches for the cost table alone is now answering a
narrower question than it thinks.

**M27 widened that gap again, and this time the street is most of the day.** The measured
numbers are in `docs/PLAYTEST-04.md`. The two worth carrying around: at act I density the
arterial has a safe gap in the traffic about **one time in twenty** — it is crossed at a zebra,
where traffic gives way, and there is one at every junction — and forty seconds of pavement
costs **eleven** contacts walked down a lane centre against **one** holding the midline between
two lanes. The crowd is expensive to be careless in and free to be careful in, and that ratio,
not either number, is what makes it a decision.

## Known-shaky ground

- **No balance number has been felt by a human.** M14 re-pitched the sleepiness numbers
  against the *day* rather than against each other, and `tests/test_balance.gd` checks the
  claim against a real city — but nobody has played it. Prime suspects are in
  `docs/TODO.md` under "Open design questions".
- **The entities do not yet read as what they are.** *(M22 closed the signalling gaps; this
  is the one it exposed.)* The vocabulary's first row is *the thing itself carries most of
  it* — and `homeless_yeller`, `busker` and `poster_crew` all draw the same `person.svg`, as
  does an ordinary crowd walker. Two of them are currently covered for by the caret above
  them, which is exactly the wrong way round: the symbol is meant to add what a silhouette
  cannot say, not to stand in for a silhouette nobody drew. First thing to fix when the art
  gets a pass.
- **There is no audio at all.** Less urgent than it sounds, given the rule above: audio is
  redundancy, so the game must already be fully playable without it.
- **Dev flags are always on.** `--seed`, `--day`, `--spawn`, `--follow`, `--meters`,
  `--overview`, `--day-length` and (in `auto_screenshot.gd`) `--screenshot`, `--after`,
  `--walk` ship in the build and live in `main.gd`. They should be gated behind a debug
  build before release.
- **Esc quits outright.** There is no pause menu; the only pause is the between-days screen.
