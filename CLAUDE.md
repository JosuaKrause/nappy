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
./tools/test.sh               # 14918 headless checks, ~55s
./tools/shot.sh out.png 3     # renders 3 seconds of real gameplay to a PNG
```

**A green `check.sh` says nothing about whether the game looks right** — headless runs never
call `_draw()`. Several real bugs in this project were found only by opening a screenshot:
building extrusions overhanging every sidewalk, zebra crossings rendering as visual static,
a fire always spawning against the map wall. If you touched anything visual, take a shot and
actually look at it.

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

**`_draw()` is retained.** It re-runs only on `queue_redraw()`, so an expensive one-off draw
(the 10k-tile city ground) is fine, but anything animated must call `queue_redraw()` itself.

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

**The telegraph fairness contract.** A player who starts walking away the instant an event
becomes visible must get clear before it hurts. `Tuning.validate_event()` asserts it on load
and `tests/test_events.gd` checks the whole catalogue. A violation is a bug, not a difficulty
setting. Two documented exemptions: `AMBIENT` events (they never "appear") and `city_wide`
ones (no edge to walk out of).

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

**No circles around entities.** *(Standing decision, playtest 02 finding 8. The aura rings
still ship today; M22 deletes them. Do not restyle them, do not add another one, and do not
reach for a ring when something new needs signalling.)*

> How dangerous a thing is has to be visible from looking at **the thing**.

A ring communicates a falloff radius, which is a number. A silhouette communicates a threat.
Where the entity cannot carry it alone, the vocabulary is: a symbol flashing **above the
entity**; a symbol at the **screen edge** whenever it is off-screen and closing, saying what
is coming and not merely that something is; and a symbol above the **player** — a flashing
exclamation mark when they are standing in a soon-to-be danger zone, plus a "too close" cue
for danger already on them. Nothing draws a field.

The exclamation mark is the load-bearing one. Every other cue says *a thing exists*; that one
says **the fairness contract is now about you and the clock has started**, which is the
difference between information and instruction.

The one property the ring had that must survive: it *breathes* with the pulse envelope, so a
pulsing event can be timed and slipped past between beats. See docs/EVENTS.md, "The visual
vocabulary".

**Audio is never the only channel.** Every cue that will eventually be audio must also exist
visually, and the visual must be sufficient on its own — the game has to play identically
with the sound off. Build the visual first and judge it alone; audio is added afterwards as
redundancy. An event whose telegraph only works "because you hear it coming" is unfinished,
and the fairness contract cannot catch it: `validate_event()` checks the geometry, not
whether the player was actually warned. See docs/EVENTS.md, "Showing the danger", for the
visual vocabulary and the two places it is currently incomplete.

---

## Recipes

**Add an event** — `src/events/event_catalogue.gd` only, in the act's section, plus a line in
the `docs/EVENTS.md` table. Everything else is data-driven. If it needs behaviour no field
covers, add the field to `EventDef` and handle it in `EventInstance` — resist adding a script
per event. `tests/test_events.gd` will fail the build if the geometry is unfair.

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
`EventBus` and holds no reference to the world.

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

Both came out of playtest 02 and neither is a bug. The full table is in `docs/EVENTS.md`,
"What an event actually costs" — regenerate it whenever a rate in `Tuning` moves, because it
is the fastest way to see what a balance change did to the whole catalogue.

- **Walking through an event is nearly free before act III.** Eleven of eighteen cost under
  fifteen points of a hundred-point meter to walk straight through the centre of, and three
  are *negative*: walking through a `dog_walker` beats walking around it, because the 3.5/s
  walking decay outruns what it emits. The escalation is entirely back-loaded into acts III
  and IV, so the days that teach the player teach them that events are safe.
- **Running is the wrong move against every event in the game.** `EXCITEMENT_FROM_RUNNING`
  plus the collapsed decay (3.5/s → 0.5/s) beats the shorter exposure every time. The run
  button is a trap. Making running *necessary* (M25) is therefore a mechanic to build —
  something that pursues, a lethal radius that grows, a window that shuts — not a constant to
  tune, and its fairness contract has to be stated over `RUN_SPEED`.

## Known-shaky ground

- **No balance number has been felt by a human.** M14 re-pitched the sleepiness numbers
  against the *day* rather than against each other, and `tests/test_balance.gd` checks the
  claim against a real city — but nobody has played it. Prime suspects are in
  `docs/TODO.md` under "Open design questions".
- **Most of what is on screen is unsignalled.** The aura rings only ever covered *events*:
  the ~530 crowd agents have none, and the two `city_wide` sources (the loudspeaker masts
  from day 5, the curfew announcement) have none either, because a field with no edge cannot
  be a ring. So on a normal street a few things are ringed, most are not, and nothing
  explains the difference. Fast movers closing from off-screen (`fire_truck`,
  `military_convoy`) spend most of their telegraph outside the viewport, where no ring can
  help. M22 replaces the whole vocabulary; see the standing decision above.
- **There is no audio at all.** Less urgent than it sounds, given the rule above: audio is
  redundancy, so the game must already be fully playable without it.
- **Dev flags are always on.** `--seed`, `--day`, `--spawn`, `--follow`, `--meters` and
  `--day-length` ship in the build and live in `main.gd`. They should be gated behind a debug
  build before release.
- **Esc quits outright.** There is no pause menu; the only pause is the between-days screen.
