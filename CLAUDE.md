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

## Verification loop

Run all three before committing. They are fast and they each catch a different class of bug.

```sh
./tools/check.sh              # imports, boots the project, fails on any script error
./tools/test.sh               # 2649 headless checks, ~21s
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

**`--script` skips autoloads.** The test suite runs as a *scene*
(`godot --headless --path . res://tests/tests.tscn`) because every test needs `Tuning`.

**An autoload name cannot also be a `class_name`.** That is why shared enums live in
`src/game_enums.gd` rather than on `GameState`.

**`SomeNode.new()` does not get the name `SomeNode`.** `Camera2D.new()` is named
`@Camera2D@41`, so a `@onready var _camera := $Camera2D` in a test rig silently fails. Set
`.name` explicitly when a node is looked up by path.

**Nodes are not refcounted.** A test double extending a `Node` class (e.g. a fake
`EventManager`) must be `free()`d by hand or it leaks. `RefCounted` doubles do not.

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
`Baby.excitement` from outside.

**`Baby` knows nothing about tiles or events.** Its entire interface to the world is three
questions: `is_calm_zone`, `is_alley`, `total_excitement_at`. Adding an event type must never
require touching the meters.

**The `CityMap` is immutable for the run.** Per-day closures are *events* with an
`obstructs_radius`, not tile edits. This is what keeps the map something the player can learn.

**The telegraph fairness contract.** A player who starts walking away the instant an event
becomes visible must get clear before it hurts. `Tuning.validate_event()` asserts it on load
and `tests/test_events.gd` checks the whole catalogue. A violation is a bug, not a difficulty
setting. Two documented exemptions: `AMBIENT` events (they never "appear") and `city_wide`
ones (no edge to walk out of).

**Every day stays winnable.** The scheduler guarantees at least one unspoiled park and a
walkable route from home to a park. If you add anything that closes streets, it must go
through those checks.

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
road / colour), then wherever the generator should emit it.

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

## Known-shaky ground

- **No balance number has been felt by a human.** They are all asserted self-consistent and
  none is playtested. Prime suspects are in `docs/TODO.md` under "Open design questions".
- **There is no audio at all.** The fire engine and the loudspeakers are both designed around
  "you hear it coming"; today every telegraph is visual only. This is the largest gap.
- **Dev flags are always on.** `--seed`, `--day`, `--spawn`, `--follow`, `--meters` and
  `--day-length` ship in the build and live in `main.gd`. They should be gated behind a debug
  build before release.
- **Esc quits outright.** There is no pause menu; the only pause is the between-days screen.
