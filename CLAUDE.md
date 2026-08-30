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

## Notes belong in the repo

**Anything worth remembering about how to work on this project goes in this file, or in a rule or
skill file beside it — never only in an assistant's private memory.** A memory is scoped to one
tool, one machine and one account: it is invisible to everybody else who opens the repo, it is not
reviewable in a diff, and it is lost the moment that store is cleared or the work moves. The repo is
the shared, versioned, reviewable place, and it is already where this project keeps its reasoning.

The same rule one level down: a note long enough to unbalance this file becomes a **rule file of its
own** rather than a longer `CLAUDE.md`. What must not happen is a note living nowhere.

### Write the feedback down with all of its detail, before doing anything about it

**Every piece of playtest feedback goes into `docs/PLAYTEST-NN.md` in full — the player's own
words, and every specific they gave — before a line of code is written.** Then it becomes a
`docs/TODO.md` item, and only then does it get implemented. A finding that was summarised on the
way in has already lost the part that was hard to work out.

*(Playtest 14 is why this is a rule and not an assumption.)* Two things were asked for, in detail,
and neither survived to the repo:

- **The border.** The brief was *"in the south there needs to be a bulkhead first then water — no
  buildings — in the east and west there needs to be a fence, then grass and forest — in the north
  there needs to be a mountainside"*, plus the two exceptions. What got written down was *"the
  border is just black"*, and what got built from it was a clamp that continued the pavement
  outward: the complaint answered, the design thrown away.
- **Hard and soft diversions.** Asked for, and there was **no note about it anywhere in the repo**
  — not in `CLAUDE.md`, not in `docs/`, not in `TODO.md`. So it was never built, and the player had
  to ask a second time whether there was any point giving feedback at all.

The failure mode is specific and it is not laziness: a finding arrives as *a complaint plus a
design*, the complaint is the part that is easy to restate, and the design is the part that took
the player thought. **Record the design even when you are about to fix the complaint**, and record
it even when you disagree with it — a note saying "asked for X, built Y instead, because Z" is a
decision somebody can overturn. Nothing else is.

And the test of whether it was written down is not "did I mention it" — it is whether somebody
opening the repo cold could **build the thing that was asked for** from what is on disk.

## Names are content, never identifiers

The mother and the baby have names — see `docs/NARRATIVE.md`, which is the one place that says
what they are. **Nothing in `src/` may be named after them.** No `hal.gd`, no `var wren`, no
`WREN_CRY_THRESHOLD`.

**Why:** a name can change at any time, and a name that has reached an identifier changes with a
rename across every file that mentions it — which is a diff nobody can review for anything else, on
a decision that was meant to be cheap to revisit. The code calls them what they *are* — `Stroller`,
`Baby`, `player`, `mother` — which is stable under every renaming the narrative might want. The
names belong in the writing: dialogue, the HUD's own strings, `docs/NARRATIVE.md`.

The same holds for anything else the fiction may rename: the city has no name for the same reason.

## Verification loop

Run all three before committing. They are fast and they each catch a different class of bug.

```sh
./tools/check.sh              # imports, boots the project, fails on any script error
./tools/test.sh               # 122119 headless checks, ~161s
./tools/test.sh crowd events  # just those suites, in seconds — for the inner loop
./tools/shot.sh out.png 3     # renders 3 seconds of real gameplay to a PNG
./tools/telemetry.sh          # what the last run actually did, in order
```

A filtered run prints `PARTIAL RUN` under its count and is not a green build. Commit on the
unfiltered one.

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

**A rig that steps the parts is not running the whole, and the gap is silent both ways.** *(M44.)*
Several suites walk the crowd by hand — `for agent in crowd.agents(): agent._process(step)` — so
that a minute of traffic does not take a minute. What that skipped is the frame *around* the agents:
`Crowd._physics_process`, which resolves the queue and, underneath it, throws `TrafficIndex` away
and rebuilds it. `claim()` is written to outlive one frame and nothing bounds it, so with nothing
rebuilding, every recycle stayed — **64,796 cars in nineteen lanes after three thousand frames**,
each scanned six times per recycle. `test_balance`'s day on the arterial was **240 of the suite's
495 seconds** for that reason alone, and all that time three suites were measuring a road with no
separation pass on it while claiming to measure the real world. `Crowd.step()` is the whole frame
and is what a rig calls now. The shape to carry: **when a rig drives a subsystem by hand, ask what
the engine was doing around it** — and if the answer is "keeping something bounded", the rig is not
slow, it is wrong. `tests/test_crowd.gd` holds it as a rule now, because nothing else could see it:
a lane full of cars that left an hour ago is still a legal lane.

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

**`--flee` is how the one encounter with a right answer gets played.** *(M35.)* A rig that can only
hold a direction can only ever demonstrate the wrong answer, so every trace of the day-3 dog taken
with `--walk` ends in a hard fail — which is the mechanic working and says nothing about whether the
answer is affordable. `--flee [delay]` turns round and runs when something starts chasing her, and
the delay is the axis worth measuring: what the right answer costs when it is given late.

**Nothing in the suite or in a screenshot has ever pressed a key, so use `--press`.** *(M36,
playtest 09: "esc doesn't work".)* The pause shipped in M33 with a screen, a key, a README line, a
`TODO.md` entry and a line in the debug overlay, and it **never opened once** — its guard read
`visible` on a `CanvasLayer`, which is true from the moment the node is in the tree. A green suite
and a screenshot both passed it for three milestones because neither of them can press Esc.
`--press <action> <seconds>` can. Note what its own first version got wrong: `Input.action_press()`
sets the **polled** state and nothing else, which is right for `--walk` and useless for anything
answered in `_unhandled_input` — it produced a screenshot of the game carrying on, which looks
exactly like the bug. Push a real event with `Input.parse_input_event`.

**And a bare key is not an action, which is the same lesson one level down.** *(M38.)* `--press`
pushed an `InputEventAction`, so it could reach `Esc` and nothing else — while `Q` (quit, since M33)
and `R` (restart, M38) are read as **keycodes**, the way a screen's own shortcuts usually are. The
rig that exists *because* nothing had ever pressed a key still could not press the two keys the
pause screen is mostly made of. `--press key:r 3.5` can, and the flag may be repeated, because one
tap can only ever photograph one screen and what usually needs checking is a sequence. Note the one
thing it cannot do: `R` reloads the scene, and the reloaded scene re-presses, so a rig restarting
the game loops for ever. Read the boot lines rather than waiting for the PNG.

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
- **Delete a branch as soon as it is fully merged, always, without being asked.** The merge commit
  is what the project keeps; the branch pointer is scaffolding. Left alone they accumulate one per
  milestone — fifty of them by M49, all identical in meaning to a line of `git log` — and the cost
  is not clutter, it is that `git branch` stops being able to answer the only question it is good
  for: **is there work that is not on `main`?** With fifty merged pointers in the way the answer
  takes a `--no-merged`; with none, the list *is* the answer.

  ```sh
  git branch --merged main | grep -v '^\*' | grep -vw main | xargs git branch -d
  ```

  `-d` and never `-D`: `-d` refuses anything not merged, so the command cannot lose work, and a
  branch it refuses is exactly the one worth looking at. (On macOS `xargs` has no `-a` — feed it
  by pipe or `< file`.)
- **One commit per `TODO.md` item, inside that one branch.** A milestone is a list of things
  that were decided separately and are each true or false on their own, so each one gets a
  commit that can be read, reverted or bisected by itself. A single commit at the end of a
  milestone throws that away and makes the branch's own history unusable.
- **Commit before stopping.** Work that is finished and green does not sit in the working tree
  waiting to be asked about: an unfinished milestone is a branch with commits on it, not a
  dirty tree. The local repository is the assistant's to manage — branch, commit and merge
  without asking each time.
- **Commit the docs in the same commit as the code.** `docs/` is not a report written
  afterwards, it is the design. If an implementation contradicts a doc, the doc is wrong and
  gets fixed in that commit. With one commit per item this means the item's own `TODO.md`
  paragraphs travel with the code that closed it, rather than in a write-up commit at the end.
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
`check.sh` exists. The form that catches people is `var x := load(path).instantiate()`, because it
reads as obviously typed and is not — and in a *test* it fails at load time, so the suite prints
nothing at all and looks like it hung. Write `var scene: PackedScene = load(path)` and
`var node: Node = scene.instantiate()`.

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

M38's title screen is the first thing that needed the split the other way round — the **city**
running while the **day** does not — and it is the same mechanism used deliberately rather than
by accident: `_city` goes back to `ALWAYS` for the duration, and `_player` is pinned to `PAUSABLE`
because she is a child of it and would otherwise inherit the exemption. That last line is the M33
bug written out as a decision instead of a mistake. Anything that wants the same trick has to name
its own exceptions the same way; there is no "pause everything except" switch and there should not
be one.

**Y-sorting compares origins, so a thing whose mass extends away from its own origin sorts
wrong.** *(M37, playtest 07 finding 4.)* A `Building`'s origin is the south edge of its lot and it
is drawn a whole block north of there, so it won every comparison against the pavement running up
the side of that block — visible only where the two also overlapped in **x**, which made a rule
look like an occasional glitch: a person (18px) never overlaps the 16px from a tile centre to the
lot edge, a lorry (62px) always does, and the things in between are the ones that move. The general
shape: **before reaching for a better comparison, ask whether the two things can ever legitimately
be on opposite sides of each other.** Here they cannot — no lot tile is walkable — so buildings are
a layer of their own and sort against nothing.

**A paused `Camera2D` with smoothing on never arrives.** *(M38.)* `position_smoothing_enabled` is
applied in the camera's **own** process callback, so a camera that is `PAUSABLE` under a paused tree
stops following the thing it is attached to and sits wherever it last was — which on the first frame
of a run is the world origin, clamped to the corner of the boundary wall. The title screen showed an
empty street for that reason and for no other: ninety-five crowd agents were walking about the
doorstep a thousand pixels off-camera, and everything the screen was meant to be showing was working
perfectly. `Stroller.stand_aside()` puts the camera on `ALWAYS` for the duration.

The thing that looks like the cause and is not, checked rather than assumed: **hiding a `Node2D`
does not deactivate a `Camera2D` under it.**

**A `Dictionary` keyed by `Vector2i` hashes a Variant on every lookup.** *(M44.)* Fine for a set of
today's closures; not fine for a flood fill. `CityMap.walk_distances` asked one about fifty thousand
times per sweep to answer a question the tile grid answers by index, and it ran twice per generation
attempt and once per day planned — 16.3ms a sweep against 4.5 for the same BFS over a flat
`PackedInt32Array`. Two things that came with it and generalise: **paint the blocked set into the
grid before the sweep** rather than asking about it per neighbour, since building a `Vector2i` four
times per tile is most of what is left; and **write the four neighbour steps out** rather than
looping an offset array, because the loop's own bounds test costs more than the arithmetic it
guards. The same shape one level down: a `Tile.is_walkable()` call per tile becomes a
`PackedByteArray` indexed by tile type, built *from* `Tile.is_walkable` so it stays the one place
that decides.

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

**And one stream shared by several *phases* is the same bug with a longer fuse.** *(M39, playtest 10
finding 5: "the tutorial dog on day 3 only appeared once (I died) then it didn't appear again".)*
`EventScheduler.build_day` ran six phases off one RNG in sequence, so anything that changed how much
an earlier phase drew moved everything after it — and a **one-shot the run had already spent was
skipped before its `randf()` was drawn**. So the second attempt at day 3, the day the fire engine
runs, started the recurring fill one value earlier and produced a different city's worth of events:
`homeless_yeller` two to eight, `cyclist` none to three, between two consecutive attempts at the
same day. `docs/TODO.md` had claimed since M32 that *"the retry is the same day"*.

`EventScheduler._stream(base, salt)` is the fix and the rule: **a phase whose consumption can vary
gets its own stream**, and inside the recurring fill each attempt gets one too, because
`_place_one` re-rolls a variable number of times and returns early when a candidate is perfect. What
is deliberately *not* closed: a scar, or a spent one-shot's 1920px route, genuinely frees ground, so
the placements that were rejected against it now fit. The composition of the day is identical and a
handful of route rows start a few tiles along the same street — which is the run's own history
showing through, and is the answer that should show through.

**The falloff has a shoulder, and the shape is a design decision.** *(M33, playtest 07 finding
18: "the excitement should go substantially up from relatively far away — I shouldn't have to get
actual contact to get penalized.")* `Tuning.falloff` is `1−t²` between the inner and outer radius,
not the `(1−t)²` it was for thirty-two milestones. The old one put a quarter of the intensity at
the midpoint of the band and six percent three quarters of the way out, so three quarters of every
radius in the game was free and an event was a thing to bump into rather than a thing to route
around. Two things follow and both are easy to get wrong:

- **The telegraph fairness contract does not care.** It is stated over *distance* — how far she
  has to walk to be outside the radius — so changing what she pays while she is inside one is not
  its business, and no radius moved. Do not "fix" the contract when the shape changes.
- **It moves the crowd too, and the crowd does not want it.** A field that bites from a distance
  is right for an authored event and wrong for one of two hundred and forty bodies, which is
  supposed to be inaudible from across the pavement. The crowd pays it back in *radius* rather
  than in intensity, so a close pass costs what it always did: `PEDESTRIAN_OUTER_RADIUS` 88 → 55,
  `CAR_OUTER_RADIUS` 170 → 104, measured against `tests/test_crowd.gd`'s arterial band.

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

**A placement is not a separation, and the separation must not be doing the placement's job.**
*(M38: "when a car turns into an occupied lane the other car just disappears.")* The rule below is
right and it was carrying more than it should. `CrowdAgent._divert()` chose an arm of a junction out
of the tile map alone, so a car diverting round a closure materialised wherever that lane happened
to be occupied — and the positional resolve then did the only thing it can, which is move a body.
Front-to-back resolution **compounds**: the shortfall a car sees is its own overlap plus everything
already moved ahead of it, so a bunched queue shunts the rearmost car several lengths backwards in
one frame. Measured at a closure: 1627 corrections in ninety seconds, worst 134px; 146 and 66px once
the turn looked first. The queue was legal on every frame either way, which is exactly why five
years of "no two cars are inside each other" tests could not see it.

Three things to carry:

- **`TrafficIndex` is the look, and it is a frame stale on purpose.** A car covers three pixels in
  a frame and the question is about a car's length.
- **Two placements in the same frame cannot see each other**, and that is not a rare case —
  recycling is what happens to every car that leaves the box, and they all aim at the same entry
  band. `TrafficIndex.claim()` is the smallest thing that closes it.
- **A retry is not a guarantee.** Six re-rolls into a busy lane all miss about once a minute, and
  then the pile is back. `_join_the_back_of_the_queue()` is the fallback, because behind the last
  car is the one place in a lane that is free by construction.

The one place a large correction is still right is **frame zero of a day**, where the crowd is
placed without consulting itself and the first pass unpacks it. Nobody has seen a previous frame of
that street to see it in. Do not "fix" it by spacing the crowd in `start_day`: that turns a random
morning into tight platoons at minimum headway, and three balance tests correctly object.

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

**`Baby` knows nothing about tiles or events.** Its entire interface to the world is four
questions: `is_calm_zone`, `decay_multiplier`, `is_alley`, `total_excitement_at`. Adding an event
type must never require touching the meters.

It was three until M41, and the fourth is worth the precedent it sets rather than the field it
adds: *the ground is a rate, not a category*. `is_calm_zone` was doing two jobs — a threshold for
the sleepiness (only calm ground puts a baby to sleep, which is genuinely a yes/no) and a
multiplier for the excitement decay (which never was). Splitting them is what let the street
hierarchy reach the meters at all — calm 2.2, precinct 1.5, ordinary 1.0, main road 0.6 — and the
shape to copy is that **the new question generalises an old answer instead of sitting beside it**.
A fifth question that is a special case of one of these four is the thing this rule exists to stop.

**The lattice is fixed; what a block *is* is not.** *(M15 replaced the old "the `CityMap`
is immutable for the run" rule with this one.)* The street lattice, the block boundaries,
the carves and the building footprints are all fixed for the run. What may change is a
block's **purpose** — a park can be requisitioned, a commercial street can go dark, a
residential block can burn — and only ever along the arc `CityGenerator` planned for it up
front. The geometry the player learns stays true; the meaning of it does not.

**The lattice is fixed and it is not a full grid.** *(M21.)* A four-block calm zone absorbs the
streets between its own blocks, so the city has one or two holes in it, four T-junctions per
hole, and a junction in the middle of each zone that nothing reaches. Three consequences, and
each is a way it goes quietly wrong:

- **Route redundancy stopped being true by construction.** A full lattice cannot be
  disconnected by removing one corridor; this one can. It is checked by search now —
  `StreetNetwork.route_count()`, which M16 already built.
- **The absent streets are a set, not a hole in the enumeration.** `StreetNetwork` still
  enumerates the full grid; `CityMap.absent_segments` says which of them this city does not
  have, and `CityMap.blocked_segments()` merges it with today's closures. **Every** route
  search takes that merged set — one that takes only the closures will happily route down the
  middle of a park and overstate the redundancy, which is the exact failure the invariant
  exists to catch.
- **A block is not the unit any more; a lot is.** `block_plans`, `block_layouts` and
  `calm_blocks` are keyed by the block that *anchors* a lot, so a zone is one entry with four
  blocks of ground. Anything counting calm areas counts a zone once. `CityMap.anchor_of()` and
  `lot_rect()` are how the other three blocks are reached.

**An absorbed street is calm ground, not a closure.** The tiles are park and the player walks
over them — a zone is a shortcut as well as a destination. Only the *lattice* lost the street,
which is why `absent_segments` is a set of segment keys and `closed_tiles` is a set of tiles.
Anything that travels the lattice (the crowd, a mobile event's route) asks `CityMap.is_street()`
instead of `is_walkable()`.

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
- **A spent plan stays spent, and a running one resumes.** Streaming may take a *running* event
  away and give it back; it may never rewind one that has finished, and the bookkeeping an event
  does once — a scar, a block arc — happens on its first instantiation and never again. *(M31
  added the second half, because only the first was implemented: a re-streamed event was rebuilt
  from the tile the day chose at dawn, so a dog walker at 32px/s teleported back to the top of
  its street every time the player left its radius and returned — which at a third of her
  walking speed is most times. It was reported as "dog walkers are not moving?", and the
  movement was fine. `Planned.age` and `Planned.travelled` carry it over.)* It **resumes** rather
  than catching up on lost time: ageing an event in absentia would put back the thing streaming
  was built to fix, a twenty-second event that is over before anybody could reach it.

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

M34 added a fifth, and it is the same shape as M28's: **a lethal radius and a solid body are the
same mechanism.** The player is stopped with her centre `obstructs_radius + PLAYER_BODY_RADIUS`
from the centre of a thing, so a `hard_fail` event whose body reaches its own inner radius can
never fire at all — which is not an unfair event, it is an event that has quietly been switched
off, and that is worse. `EventDef.validate()` refuses the arrangement on load. It is why giving
`alley_robbery` a body meant moving its inner radius from 22 to 30: the pram would otherwise have
been held three pixels outside the thing that takes the baby.

**Nothing vanishes while you are looking at it.** *(M35, playtest 08 findings 2 and 3: "things that
move disappear on screen; they should at least run offscreen before despawning", and "pigeons are
also completely ineffective", which is the same sentence.)* The end of an event was `_finish()`
wherever it happened to be standing, which for the two shortest-lived rows in the game is directly
in front of her. An event that is over **leaves**: `EventInstance._be_done()` puts it in a leaving
phase where it emits nothing, cannot end the day and carries no cue, and it moves until it is past
`Tuning.OUT_OF_SIGHT` before it is deleted. Three things to keep straight:

- **Anything `mobile` leaves at its own `speed` and needs no data.** `EventDef.departs_at` is for the
  rest — a flock, which has to fly, and a pursuer that has lost interest.
- **It is over the moment it starts leaving.** A cat that trailed its field behind it for the two
  seconds it took to reach the kerb would be a worse bug than the one being fixed.
- **Two things never leave**, and both would break something that reads the finishing position: an
  event with a `spawns_on_finish` stops where the thing it leaves belongs, and anything that was a
  *place* rather than a moment has always simply been over. Do not "fix" a café that does not walk
  home.

**A fairness contract stated in seconds is not stated at all.** *(M35, playtest 08 finding 4.)*
`validate_pursuit` bought the day-3 dog 2.4s of telegraph and never asked **where it spends them**:
the director sites what the day owes 184px in front of her, which is where she was already walking,
so it closed the gap in three quarters of a second and stood *inside its own lethal radius* for the
rest of a phase whose entire purpose is to be a warning. Every line of the contract passed while it
killed people, three attempts running. The rule the fix is an instance of: **when a contract is
about a moving encounter, state it over distance and check it by walking, not by asserting the
numbers it was written from.** `Tuning.pursuit_standoff()` is the notice as a distance;
`tests/test_events.gd` walks the answers rather than restating either. Four traps inside it, all
found by doing it:

- **Clamping the approach at zero is not a stand-off.** It leaves the dog standing politely still
  while *she* closes the last hundred pixels and dies on the first lethal frame — the contract true
  of the thing and false of the encounter. It has to back off. The price of that is the wart:
  backing off is what it does for the rest of a telegraph once it has arrived, and a stand-off wide
  enough to be seen doing it is a dog that visibly reverses.
- **A break-off stated as a distance needs two inequalities and they fight.** "Walking cannot reach
  it inside the chase" and "running can" are the same three numbers pulling opposite ways, so
  widening a stand-off silently ate an escape and a robber's trigger — which has to fit *between*
  them — once had eleven pixels to live in. `PURSUIT_SHAKEN_OFF` ends a chase at a **rate**: the
  pursuer is faster than a walk and slower than a run by construction, so *only running can open the
  gap*, and both halves of the design fall out of the speed clauses that were already there.
- **Check it with a rig that accelerates.** The three walks in `tests/test_events.gd` all held a
  constant speed from frame one, and all three passed while a player was reporting the encounter as
  unplayable — because nobody can turn round in nought seconds. Reversing a walk into a run takes
  `(WALK + RUN) / ACCELERATION` and hands the thing 34px before the run gains a pixel. The general
  shape, and it is the third time this project has learnt it: **when a contract is about an
  encounter, put every body in the encounter into it — including the cost of the player's own
  answer.**
- **A rig that runs on a timer runs into it.** The director sites what it owes in front of the
  direction she is *actually travelling*, so a `--flee` that starts before the pursuit is placed
  puts the pursuit in front of the run. It waits for the chase now.

And the open half, recorded because a green contract is not a played one: at the lunge she is
walking *into* the thing, so the gap closes at `pursue_speed + WALK_SPEED` and the window to answer
is about **0.2s**, not the `PURSUIT_REACTION` it was bought with. A player answers during the
telegraph instead, where it is visible and closing for two and a half seconds. Widening the window
means widening the stand-off, which is the first bullet's wart. See `docs/PLAYTEST-10.md`, C.

**A pursuit has two shapes and a third state.** *(M36, playtest 09: "a robber should increase
excitement on sight and getting close to them should be day ending", and "if you get close they
should start moving towards you".)* `charging_dog` is a **moment** — the director sites it in front
of her and the chase is all of it. `EventDef.pursues_within` is the other shape: a thing that is
*somewhere*, that can be seen and priced and routed around, and that becomes a chase if she walks up
to it. Two things about the waiting state are easy to get backwards:

- **The clock starts when it notices her**, not when the day put it there. A robbery whose telegraph
  ran at dawn four streets away arrives with no notice in it at all.
- **Its notice does not damp what it emits.** `TELEGRAPH_INTENSITY_FRACTION` means *this has not
  started yet*; a man standing in that alley has started, and what has not started is the lunge. It
  is the one telegraph in the game that does not quieten the thing it is warning about.

And the trap that was found by measuring rather than thinking, kept because the shape of it recurs:
while the chase ended at a **distance**, a trigger at or past that distance was a pursuit that lost
interest the instant it started — she was already standing where "it has lost her" means — so the
rig strolled away from him every time, and walking away is the one answer that must never work. A
break-off stated as a rate cannot reproduce it at any trigger distance.

**A fixture can move, and `EventDef.paces` is how.** *(M36, playtest 09: "it didn't move and it took
a long time to have any effect… if it's the homeless person it needs to walk up and down the
sidewalk".)* A **beat** rather than a journey: it walks its route, turns round at the ends, and
neither departs nor expires. The difference matters because a stationary source is a fixed price on
a fixed patch of ground — a line you draw once and never think about again — and a man pacing two
hundred and fifty pixels of footway is a timing problem on top of a routing one. The price is the
body: anything mobile is exempt from the rule below, so making something pace **takes its
`obstructs_radius` away**, and what has to replace it is intensity.

**Anything that stands still is solid at the width it is drawn.** *(M34, playtest 07 findings 16
and 13: "none of the non-moving obstacles do anything — I can freely walk over them", and "I can
walk over the robber and he doesn't do anything".)* `obstructs_radius` was set on five rows of
thirty because it had only ever been reached for when one event wanted to block a pavement, so a
delivery van was scenery and a man on the pavement could be stood on. The number is **half the
silhouette** and not a balance value — `EventInstance._draw_spread` already draws a blocking object
at exactly the width it obstructs for the same reason in the other direction. Three exemptions,
each written down in `docs/EVENTS.md`, "Solid things are solid": anything **mobile** (a moving
wall pins her — the M19 `dog_walker` decision), anything `AHEAD_OF_PLAYER` (`validate()` refuses
it), and anything with no silhouette. `tests/test_events.gd` walks the catalogue and requires
everything else to have one, so this stays a rule rather than going back to being a list.

The knock-on to watch: a body is a **route** cost, and several rules were written when only
scaffolding had one. `EventScheduler._something_to_put_in_a_park` refused *anything* that
obstructs, which meant "nothing that closes the ground" right up until a busker became solid;
`Tuning.OBSTRUCTION_A_PARK_CAN_HOLD` is that rule restated as what it always meant. If a rule
tests `obstructs_radius > 0`, ask whether it means *has a body* or *closes ground*.

**The traffic fairness contract.** *(M19.)* A car is lethal and is **not** an event, so
`validate_event()` never sees it. `Tuning.validate_traffic()` is its equivalent and runs on
boot. Two things stand in for the telegraph: the painted carriageway, which is permanent and
learnable and which she chooses to step onto, and the horn, which must be long enough to walk
the whole width of it with the doubled hard-fail margin. If anything else in the game ever
becomes lethal without being in the catalogue, it needs its own stated contract in the same
place — a hard fail with no written contract is a bug waiting to be called a difficulty
setting.

**And the main road replaces the courtesy with a clock, so the clock is the contract.** *(M41.)*
Traffic on the spine does not give way at a zebra — what stops it is the light — so the thing
standing between her and a hard fail there is the length of the **side street's** green, and
`Tuning.validate_signals()` states it in the same place and the same shape: long enough to walk the
carriageway with the doubled margin. Two things about that are easy to get backwards. The green
that matters is the *other* arm's, because she crosses the main road while the main road is
stopped; and the amber is a **clearance** period rather than a warning — the crossing arm stays red
through it and a car too close to stop is counted as already in the box — so lengthening it buys
her nothing and lengthening the side green buys her everything.

**A lane is a queue; a junction is a box.** *(M41, playtest 11 finding 7: "cars overlap on
intersections".)* M38 made a car turning into an occupied *lane* look first and the box was never
modelled, so two cars on crossing arms each read a clear lane ahead and both entered: **3,776
overlapping crossing-axis pairs in ninety seconds of the arterial, one in half of all frames**, with
every assertion about the traffic passing throughout. `Crowd.give_way_at_junctions()` is the rule
and four clauses of it are load-bearing:

- **Only crossing traffic conflicts.** Two cars meeting head-on are in different lanes and pass.
- **A car that cannot stop is counted as already in the box**, not asked to brake — the zebra's
  commit rule, for the same reason: braking too late means stopping *in* the thing.
- **Nothing enters a box it cannot leave.** Without this one clause a single backed-up queue takes
  the streets either side of it with it — five of forty-six cars parked in a box, measured.
- **Nearest first, then right before left.** Distance alone leaves a symmetric arrival undecided
  and right-before-left alone deadlocks four cars in a ring; in that order there is exactly one
  winner per box per frame. A light overrides the whole negotiation where there is one.

The collision that gets through is deliberate and is **not** a catalogue row: it startles the cars
it happened to, which is M19's mechanism and composes by addition like every other body. An event
nobody meets in a run is a silhouette and a fairness contract spent on decoration.

**A signalled grid has a capacity, and the population has to respect it.** Two more measured facts
that generalise. Signals with arbitrary offsets stop a car at *every* junction — two thirds of the
traffic stationary — so the cycle is derived from the block spacing (`SIGNAL_PROGRESSION_BLOCKS`).
And junction control gave the road a throughput it never had, so the car population is now a number
about capacity as well as about noise: the same forty-six cars put the arterial's floor over the
ceiling `tests/test_crowd.gd` states, because a car waiting at a light beside you is louder for
longer than one going past.

**The green wave serves one direction, and for five milestones the docs said two.** *(M46.)* M41
wrote that both directions progress "because the cycle is an **even** multiple of the
junction-to-junction travelling time", and that is the condition upside down: with offsets
`j·travel`, a car going *with* the wave holds its phase exactly, and one going *against* it
advances `2·travel` per junction, which is only constant if the cycle **divides** `2·travel` — true
at `blocks = 1` and nowhere else. Measured on the wave alone, no traffic in it: **93% of arrivals
green with it, 51% against it**, and 51% is the main green's share of the cycle, i.e. chance.

Three things to carry, because the shape recurs:

- **A two-way wave is not available at any setting of this constant.** It needs `cycle = 2·travel`
  = 5.7s and the side green plus its ambers is 9.0s before the main road gets a second. The
  asymmetric offset is the *best* answer, not a compromise: `θ = travel` gives 72% overall, and
  `θ = cycle/2` — the symmetric-looking one — puts both directions on a three-phase sweep at 47%.
- **An identity is not the property.** `tests/test_crowd.gd` asserted `cycle / travel` is an even
  multiple for five milestones. That was *true* and pinned nothing, because it was not the
  condition the sentence beside it claimed. It walks a car down the platoon now.
- **The stopped fraction was blamed on the speed spread and it is not that.** `CAR_SPEED` is
  130–185 against a wave tuned for 157.5, so a slow car drifts 0.6s per junction — but a car lives
  3.8 junctions on the spine and needs 13 to drift out of a green band, and measured, the **fast**
  half stopped more than the slow half. Drift is real and it is not the mechanism. The mechanism is
  that the main arm is red 53% of the cycle and only half the traffic gets the wave.

**A gap is a snapshot, and *do not block the box* has to know the queue is moving.** *(M46.)*
`Crowd._can_clear_the_box` compared a static `gap_ahead` against the room a car needs beyond a
junction, so a car sitting behind a leader that was already accelerating away refused to enter,
stopped, and created the jam the rule exists to prevent. Crediting the leader's speed for one
`CAR_HEADWAY_TIME` — the same horizon the car-following rule already trusts it for — took the spine
from **44.6 to 53.6 px/s and 43% stopped to 39%**, with 37% fewer stops per car and the crossing
cost unmoved at ~30.

The half that had to be walked back is the instructive one: crediting it **unconditionally** put
238 overlapping crossing-axis pairs in 3,600 frames against a tolerance of 180, because it let a
car follow its leader *into* the box. The credit is only sound when the leader is already past the
far side — then the leader's speed answers "will the last 66px have opened up", which is a
question about road this car is not yet on. **Ask what the number you are crediting is a fact
about**: a leader inside the box is the obstacle, not evidence about the road beyond it.

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
itself** carries most of it; a **caret above the entity** for anything worth changing your route
for, amber for *go round it* and doubled deep red for *it ends your day*, flashing while it has not
started yet; a **badge at the screen edge** whenever something lethal or faster than a
walk is off-screen and closing **under its own steam**, carrying its own silhouette so it says
what is coming rather than that something is; above the **player** a flashing exclamation mark
for a soon-to-be-bad spot, doubled and red for danger already on her; and over the **pram**, the
only cue that is not about the world — four states of the baby herself, added in M32. Nothing
draws a field.

Four rules that are easy to lose and are the whole reason it is better than the rings:

- **The entity carries most of it, so one picture per row.** *(M37, playtest 07 finding 2: "not
  sure what that person was supposed to be".)* Every rule below is about what to add *on top of*
  a legible entity, and for thirty-six milestones the entity underneath often was not one:
  `EventDef.Look` opened with five **categories** — `PERSON`, `VEHICLE`, `OBJECT`, `ANIMAL`,
  `FIRE` — and a category is a thing you can always put one more row into, so sixteen of the
  twenty-eight visible rows drew five pictures between them.

  **It reads as an art chore and it was costing findings**, which is the part to carry. M34 spent
  a milestone fixing `alley_robbery` for a complaint about `homeless_yeller`, because a player can
  only say *"the robber"* and the two drew the same man; playtest 09 then asked *"who is the person
  killing me?"*. And the one cue whose entire content is **what** is coming — the screen-edge badge
  — was drawing a delivery van for a fire engine, because `DangerEdge` kept a *second* table of
  which picture a look meant.

  So: **no two rows share a look, no two looks share a silhouette**, `EventInstance.icon_for()` is
  the single table, and there is no generic left to reach for. `tests/test_events.gd` holds both
  halves, which is what stops this going back to being a list — the M34 `obstructs_radius` move on
  the other half of the vocabulary. The **crowd** is the deliberate opposite: two hundred and forty
  bodies share one `person.svg`, because a crowd is what an authored event has to stand out from.
- **A cue that marks everything says nothing, and a cue that marks the wrong things says something
  false.** The rings marked a notice board exactly as hard as an abduction, which is most of why
  they explained nothing — so M22 narrowed the caret to *lethal, telegraphing, pulsing or swelling*,
  which is **danger that changes over time**, and M33 tightened the pulse clause. Both were right
  about what they were fixing and neither is a statement about **how bad it is**.

  *(M39, playtest 10 findings 1, 8 and 9.)* Fifteen milestones later the marked set and the danger
  had come apart completely: a **fire engine** (+115) carried nothing and a **burning building**
  (+56) carried a caret; a **dog walker** (+36, the most expensive ordinary row in act I and the
  subject of two playtests) carried nothing while the **leaf blower** beside it did, because its
  beat is 4.0s rather than 8.0s; and **`homeless_yeller`** (+31) — the man who ends day 1 in three
  separate traces — missed the pulse rule by four tenths of a second, which is finding 1 exactly.

  So the rule is the player's own expectation, and it is stated as an **invariant a test can hold**
  rather than as a condition: **if A is marked and B is not, A costs more to walk through than B.**
  `EventDef.walk_through_cost()` is the order, `Tuning.MARK_WORTH_A_DETOUR` is where the line falls,
  lethal is marked whatever it costs, and `tests/test_danger.gd` asserts the monotonicity over the
  whole catalogue plus the thing M22 was right about — the whole catalogue is never marked at once,
  and day 1 leaves its cheap end alone.

  Two things worth carrying beyond this row. **The cost integral moved out of the test and onto
  `EventDef`**, because the game now asks the question the test was asking and two copies of it is
  the `DangerEdge` defect M37 found. And **a colour is the wrong channel for a phase**: amber meant
  *telegraphing*, but `EVENT_STREAM_RADIUS` is 900px and no telegraph is longer than 4s, so amber
  was only ever seen on the two `AHEAD_OF_PLAYER` rows and in play it meant *near*. The flash
  carries the phase now, because a flash is a property of the mark rather than of a moment she had
  to be present for.
- **The mark breathes**, tracking current emission, which is the one thing the ring did that a
  discrete symbol does not get for free. Without it a pulsing event stops being something to
  time a pass through and becomes something that hurts at random.
- **A cue is a claim about a *moment*.** *(M32, playtest 06 findings 1 and 3.)* The two rules
  above are both about *which* things a cue is raised for. Both were right, and the next two
  complaints were about **when**: the mark stayed up on the pavement after the car had gone, and
  the badge announced anything lethal she happened to walk towards. Two halves, and both are
  worth copying rather than merely fixing. **A cue is lowered by the system that can see its
  condition**: `Stroller.warn()` takes a source and `stand_down()` lowers only that source's own
  mark, so a hold that bridges a gap in the danger (the space between two cars in one lane) does
  not also bridge the danger being over. And **measure the thing, not the gap**: the badge's
  closing speed is now the event's own approach with the player held still, because a rate that
  includes her 92px/s is a cue for walking. Nothing in `tests/test_danger.gd` can see a moment,
  which is why both defects reached a player; the `cue` telemetry entry exists so the next one
  does not.

  *(M39, playtest 10 finding 11: "when I'm walking orthogonally away from the biker the double !!
  shouldn't show anymore since there is no way it can affect me".)* M32 fixed the traffic half and
  the **events** half kept "inside the outer radius" — so a cyclist lethal inside 26px raised the
  strongest cue in the game across 145 and held it while the bike rode away. `NOW` is two conditions
  now: within `LETHAL_MARK_LEAD` of the radius that ends the day, **and** closing. And note that it
  uses the **relative** rate where the badge deliberately uses the thing's own: the badge says *a
  thing exists and is coming*, so her walking must not raise one, and this mark says *the contract
  is now about you*, which is a statement about the pair of them. Two cues, two sentences, two
  answers to the same-looking question — do not unify them.

The exclamation mark is the load-bearing one. Every other cue says *a thing exists*; that one
says **the fairness contract is now about you and the clock has started**, which is the
difference between information and instruction. *(M30 narrowed it to what that sentence actually
promises: only a `hard_fail` event and a closing car raise it. Raised for every telegraph, as
M22 had it, it meant "a number is about to move faster" for fifteen of the eighteen rows — which
the meter already says — and the player's verdict was "I can just keep doing what I was doing".
That is the marks-everything mistake arriving at the one cue that cannot afford it.)*

**A cue that belongs to the vocabulary does not belong to a class.** *(M30.)* The caret was a
private method on `EventInstance`, so "the entity carries its own cue" quietly meant "the
*event* entity does", and the one lethal thing in the game that is not in the catalogue — a car
— had nothing at all. It lives in `Sprites.draw_caret()` now. If a new kind of thing needs a
cue from the table, it draws the same shape from the same place; a second hand-drawn chevron is
how a deliberately short vocabulary gets long. `Stroller.warn()` is additive rather than a
setter for a reason: the crowd and the events both watch the ground she is standing on in the
same frame, and a setter lets whichever runs second clear what the first just said. *(M32 added
`stand_down(source)`, which is the smallest thing that is not a setter: a caller may lower the
mark **it** raised and nothing else, so a system that has been outbid by something louder finds
nothing of its own to take down.)*

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

**And the budget is per block, because the target is per block.** `budget_for()` multiplies by
`CITY_BLOCKS.x * CITY_BLOCKS.y`. A flat budget is a statement about one lattice size and nothing
else: grow the city and the same events spread thinner, which is the density silently falling while
every constant in the file still reads as correct. The general shape, and it is worth applying to
the next constant that looks absolute: **ask what a number is per.** The crowd is the deliberate
opposite — it is a population of the *field* around the player rather than of the city, so it does
**not** scale with the lattice, and a resize changes it only through `CrowdField.corridor_range`
clamping the box against the boundary.

**And a thing made of several bodies has to be made of several bodies.** *(M38: "the birds are
broken — they start the flying animation but then freeze. Turn them into individual entities and let
each fly and make them dangerous.")* A flock was one sprite drawn seven times at offsets derived
from the instance's own position — which is the right trick for a picture that must not boil, and
the wrong one for a picture that must move, because it means the seven birds *cannot* move relative
to each other. The whole animation was one `rise` term that reached 1.0 at the end of the telegraph
and then held.

`EventDef.flock_size` is the fix and three things about it are worth copying:

- **The excitement stays a pure query, one level down.** The world sums `contribution_at()` over
  instances; a flock sums over its birds. That is the invariant working, not an exception to it —
  and it is what makes the middle of a flock cost five times the rim, which is a *route* decision
  where one disc could only ever be a price.
- **The birds are held inside `flock_spread`, and `flock_spread` comes out of `outer_radius`.**
  A bird emits over `outer_radius - flock_spread`, so the union of eleven moving fields is inside
  the one disc `validate_event` checked. A moving emitter is only legal while that is true.
- **`lerp` cannot turn a vector round.** Interpolating a unit vector toward its opposite runs down
  the same line to zero and back out the way it came, so normalising gives the heading it started
  with — and the one bird the containment could not turn was the one flying straight out of the
  flock. It went 202px out of a 62px wheel while the code holding it ran every frame. Rotate by a
  bounded angle (`EventInstance._steer`), and steer from *half way out*, because a turn costs
  ground.

**A moving thing has to look like it is moving.** *(M31.)* Every crowd agent has a two-frame
stride and an `EventInstance` had none, so a dog walker at 32px/s — a tile a second against the
player's three — slid along with nothing on it changing and read as parked. The fix is a bob
driven by **distance covered** rather than by time, so what shows is the movement itself: a
stopped thing is still and a fast thing bobs faster. A sprite cannot swing its own legs (M12c),
so a bob is what there is.

**Add an event** — `src/events/event_catalogue.gd` in the act's section, a line in the
`docs/EVENTS.md` table, and **a drawing**: an `EventDef.Look` of its own, an SVG in
`assets/events/`, a `_draw_*` in `EventInstance`, and a row in `EventInstance.icon_for()` so the
screen-edge badge has a silhouette. That last part is not optional and there is no generic to
borrow — see the invariant above; `tests/test_events.gd` fails the build if two rows share a
picture. Everything else is data-driven. If it needs behaviour no field
covers, add the field to `EventDef` and handle it in `EventInstance` — resist adding a script
per event. `tests/test_events.gd` will fail the build if the geometry is unfair.

Decide `spawn_mode` deliberately. `MAP` is the default and is right for anything the player
could plan around: it is a place, and finding out it is there is what walking a street is for.
`AHEAD_OF_PLAYER` is for the small number whose entire content is *the moment it happens to
you* — three seconds of cat is not a place — and it may not obstruct.

`flock_size` is the one field that changes what a row *is* rather than what it does: it makes the
event several bodies, and `contribution_at` then sums over them. Reach for it only when the event
genuinely is a number of creatures, and set `flock_spread` out of `outer_radius` rather than on top
of it — see the invariant above.

`obstructs_radius` is **not** a decision: if it stands still and it is drawn, it is solid at half
its silhouette (see the invariant above). `pavement_side` usually is not one either — `ANY` is
right for almost everything, and the two rows that use it do so because a parked vehicle belongs
at a kerb and a thing that reverses into a yard needs a wall. `departs_at` is only a decision for a
**stationary** event with a `duration`: anything mobile already leaves at its own speed, and
anything without a duration never ends.

**Change the crowd density** — `Tuning.CROWD_PEDESTRIANS_PER_ACT` / `CROWD_CARS_PER_ACT`, which
since M27 are populations of the **field** rather than of the city, and
`CrowdLanes.ARTERIAL_BUSYNESS`, which is one street's share of the three or four corridors in
the box rather than of sixteen. Then **measure it**, with a throwaway probe over a minute of a
real day: how often there is a safe gap to cross the arterial and an ordinary street, the mean
wait at the kerb, contacts in a forty-second walk down a lane centre *and* holding the midline
between two lanes, and whether any two cars share a lane closer than a car's length. The table
in `docs/PLAYTEST-04.md` is what those came out as, and re-measuring is the only honest way to
move them: a lane has a **capacity**, and past it the arterial jams solid and no controller
helps. **Since M41 the junctions have a capacity too**, so the car number is no longer only a noise
number — measure the mean speed and the stopped fraction alongside the floor, or a road that reads
as "busy" in a screenshot is a car park in motion.

**Change the street hierarchy** — `CityGenerator._assign_street_kinds` decides *where*
(`CityMap.main_road`, `CityMap.precinct_spans`); `Tuning.PRECINCT_BLOCKS`,
`PRECINCT_BUSYNESS`, `EVENT_PRECINCT_WEIGHT` and the `EXCITEMENT_DECAY_*_MULTIPLIER` trio decide
*what it means*. Four places have to agree and the failure mode of each is silent:
`GroundTiles` (what it looks like), `CrowdLanes.busyness_for` + `walkable_offsets` (who walks and
drives there), `City.decay_multiplier` (what the ground does to the meter), and
`TrafficSignals.is_signalled` (whether its junctions have lights).

The trap is scale. **There is one main road and there are two precincts, and that is the design
rather than a parameter** — the first build made one of each per *axis* and the report was that
the city had three kinds of street and no hierarchy among them. If a kind starts appearing in
every third corridor, it has stopped being a place.

**And a correction that reaches four files reaches four files.** *(M46, playtest 13 finding 7: "the
main road doesn't really have much traffic I can freely walk over it".)* M41's *one of the top
thing* landed in `street_kind`, `GroundTiles`, `TrafficSignals` and `decay_multiplier` — and not in
`CrowdLanes.busyness`, which went on computing the answer itself as `index == arterial_index(blocks)`
with `blocks` from whichever axis it was asked about. So the middle corridor of **each** axis was
weighted as an arterial, and the phantom east-west one held **14.6 cars against the spine's 11.2**:
more traffic on a street with no lights, no dark asphalt and no clearway than on the one with all
three. It takes the map now, because *which corridor is the main road* is a fact about a city.

**The deeper half is that a weighting applied inside a fixed split cannot cross it.** `_choose_lane`
picked the axis 50/50 *before* the corridor, so `busyness` could only ever redistribute cars within
an axis and **no weight at all — 5, 50, any number — could put more than half the traffic on one
north-south street.** Cars pick their axis by weight now; walkers keep the even split on purpose,
because a pavement has no hierarchy for them to follow. The general shape, and it is worth checking
for wherever this project weights anything: **ask what the weight is competing inside of.** A
number that looks like a global priority is a local one if something upstream has already chosen
the bracket.

Two consequences that came with it and are not obvious. **The car population is a capacity number,
not only a noise one** — the spine went 11.2 → 15.4 cars and forty of them put junction contention
over the rate `tests/test_crowd.gd` allows, so the honest answer to *"the main road is too quiet"*
was **fewer cars**, for the second time. And **a retry is not a guarantee, one scale out**: a car
handed a corridor whose visible stretch is all precinct re-rolled its position eight times, found
bollards every time, and was placed among them anyway. When re-rolling the small decision keeps
failing, re-take the big one — `CrowdAgent.setup` picks another street now.

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
`validate()` will tell you, on every seed, if it does not. Write it against
`map.lot_rect(block)` rather than `CityMap.block_rect(block)`, or it will be a quarter of the
ground on a four-block calm zone and nobody will notice on the 45 lots that are one block.

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

- **Walking through an event used to be nearly free before act III**, and it took three
  milestones to fix. M19 dealt with the worst rows — `dog_walker` cost −0.1 points to walk
  straight through the centre of, so ploughing into it beat going round — and **M33 dealt with
  the shape underneath all of them**: `Tuning.falloff` was `(1−t)²`, which is six percent of
  intensity three quarters of the way out, so an event only charged for itself on contact. It is
  `1−t²` now, three quarters at the midpoint. `dog_walker` is +36.5, `cafe_tables` +20.1, and one
  row stays negative on purpose — `burnt_shell` is a reminder rather than an obstacle.
  `tests/test_events.gd` names exactly that one as the exemption, so a **second** negative event
  has to be a decision somebody takes rather than a number nobody checked.
- **Running is the wrong move against every event you route *around*, and the right move
  against the one kind of thing that follows you.** *(M33 built the exception; the rule is
  otherwise unchanged.)* `EXCITEMENT_FROM_RUNNING` plus the collapsed decay (3.5/s → 0.5/s)
  beats the shorter exposure for every row that merely emits, and `tests/test_events.gd` asserts
  it row by row now — it had only ever been *measured* and written down here, and M33's change to
  the falloff shape broke it silently in four rows before anyone noticed. The exception is
  `EventDef.pursues`: faster than a walk, slower than a run, lethal, and it gives up. Walking and
  running give **opposite outcomes** rather than the same outcome at two prices, which is exactly
  why it had to be a mechanic rather than a constant. `Tuning.validate_pursuit()` is its fairness
  contract and it is stated over `RUN_SPEED`, and nothing pursues before `Tuning.RUN_TAUGHT_DAY`
  — day 1 teaches the arrow keys and day 3 teaches the run, with the thing that requires it.
  *(M35 added the half M33 left out: **it gives up** has to mean "when she has beaten it", not "when
  the clock says so", or the right answer is priced the same however well it is played. It costs
  21–24 points now, and reacting sooner costs less.)*

**And one fact the table does not cover.** Since M19 the cost of a route is no longer only the
events on it: a contact with a pedestrian is ~10.8 points and a car's horn ~8, and neither is
in the catalogue. A balance argument that reaches for the cost table alone is now answering a
narrower question than it thinks.

**M34 made most of the table unwalkable, which does not change a number in it.** Every stationary
row is solid now, so "walk straight through the centre" is a line the player cannot take against
about two thirds of the catalogue. The integral is still the right price for *being close*, and
being stopped by a body is a route cost the table has never counted — day 1 goes from 12.2
pavement-blocking obstacles to 17.2, measured over five seeds, with the count of events placed
unchanged at ~39.

**M27 widened that gap again, and this time the street is most of the day.** The measured
numbers are in `docs/PLAYTEST-04.md`. The two worth carrying around: at act I density the
arterial has a safe gap in the traffic about **one time in twenty** — it is crossed at a zebra,
where traffic gives way, and there is one at every junction — and forty seconds of pavement
costs **eleven** contacts walked down a lane centre against **one** holding the midline between
two lanes. The crowd is expensive to be careless in and free to be careful in, and that ratio,
not either number, is what makes it a decision.

**Re-measured in M46, and the careful line is back — which means the M33 note above is stale and
this is why numbers get re-measured rather than quoted.** M33 found the ratio collapsed to
thirteen against fifteen and answered it with a *behaviour* (somebody who sees a pram coming steps
aside). Five seeds of forty-second walks on `main` now give **73 contacts down a lane centre
against 5 on the midline — 14.6:1**, better than the 11:1 M19 built the crowd on. Nobody
re-measured after M41 moved the crowd, so the project carried "the careful line is gone" through
four milestones after it stopped being true.

**So the open half was not that the careful line is absent, it is that it was invisible — and the
cause was that it was four pixels wide.** A contact fires inside `BUMP_RADIUS` of a lane centre and
the lanes sat a tile apart, so the line with nothing on it was `32 − 2 × 14`. That is not something
a player aims at, it is something she is occasionally on, and 165 points of a hundred rode on it:
forty seconds down an arterial lane centre costs 15.3 contacts and the midline costs none.

`CrowdLanes.SIDEWALK_LANE_SPREAD` widens it to 20px by moving the two lanes of a footway toward the
pavement's own edges. **Widen the street, not the body** — `BUMP_RADIUS` is what makes a contact
mean *walking into somebody*, and buying the same line by shrinking it would make a contact require
a near-perfect overlap. Two things fell out and the second is the one worth carrying:

- **The careless line stayed careless** (13.7 → 15.3 contacts down a lane centre), which it had to.
  A crowd is only a decision if walking down the middle of it still costs.
- **The field wants the same line now.** Walkers further from the middle of the pavement means the
  midline is 24px from each lane rather than 16 — outside `PEDESTRIAN_INNER_RADIUS` instead of
  inside it — and the ambient cost of an ordinary midline fell 74 → 56 per forty seconds. Before
  this, contacts and noise wanted **opposite** lines and a player who found one had found the
  other's punishment. When two systems price the same choice, check they are not pricing it in
  opposite directions; that is not a balance error, it is a design that cannot be played.

And one number this corrected on the way past: the *ordinary* street was never the problem. Every
line across an ordinary footway is **net recovery** while walking — the crowd charges 55–87 points
over forty seconds against a decay that pays back 140. Walking an ordinary pavement is free;
**standing** on one is not, which is `EXCITEMENT_DECAY_IDLE` and not the crowd. See M46 in
`docs/TODO.md`.

## Known-shaky ground

- **The difficulty has now been felt by a human, once.** *(Playtest 06, finding 2: "I like the
  difficulty now — it actually became harder.")* That is a verdict on M28's density and M31's
  act I teeth and nothing else. The sleepiness numbers M14 pitched against the *day*, the nerve
  economy, and whether the arterial is crossable are all still arithmetic checked by
  `tests/test_balance.gd` and unfelt. Prime suspects are in `docs/TODO.md` under "Open design
  questions". *(M32 moved the nerve economy rather than settling it: a lost day is retried now,
  so three nerves are three attempts rather than three days off the calendar, and nobody has
  played that either.)* *(M35 moved it again and did not settle it either: five nerves, because
  playtest 08's run ended on day 3 — but two of those went on a **defect**, so the number was raised
  against a difficulty that no longer exists. If act I now reads as fair, five may be generous.)*
- **The day-3 lesson is settled, and it is the one entry here that a player has closed.**
  *(Playtest 14: "the pursuing dog is perfect now — when I walk away I die, if I run a bit I get
  rid of the dog. Perfect balance.")* It stood open from M35 to M49 saying every answer was a
  rig's, and three playtests reported the encounter broken while the rig kept passing.

  **What was wrong was never a number.** The speeds, the stand-off, the telegraph and the chase
  clock were all tuned, repeatedly, and none of them was the fault: `PURSUIT_SHAKEN_OFF` ended the
  chase when *the gap had been opening for 0.8s*, which is the design's sentence — *run and it
  gives up* — restated as a fact about geometry. Against this dog a run opens the gap at 38px/s, a
  fifth of a pixel a frame, so a corner, a kerb, a body in the way or the 0.37s about-turn reset it
  to zero and the dog chased somebody who was plainly sprinting. Stating it about **her** fixed it
  in one line and took the cost of the right answer from 17 points to 5.

  The shape to carry, because this project has now paid for it three times: **when a rule is about
  what the player did, state it over the player.** A proxy that is equivalent in the ideal case is
  not equivalent in a street, and every measurement you take of the proxy will agree with you.
- **A spoiled park is now nine things and nobody has stood in one.** *(M35.)* The coverage is
  measured — 91% of a courtyard, 99% of a four-block zone — and what is not measured is whether it
  reads as *the park is busy today* or as somebody having tipped an event budget into a field. It is
  also the one place in the game where `EVENT_SPACING_SAME` does not apply, which is deliberate and
  is exactly the rule that exists to stop a street looking like a duplicated sprite.
- **The robber has never been met and act III has never been reached.** *(M36.)* Every number on him
  is a rig's, and the row is now the most mechanically complicated in the catalogue — a field, a
  trigger, a notice, a stand-off and a break-off. No playtest has got past **day 3**, so the whole of
  acts II–IV is arithmetic checked by tests and seen by nobody, and this row is the newest part of
  it. The `chase` entries are what to read the day somebody gets there.
- **A pacing man has not been walked past by a person either.** *(M36.)* He is the fix for a
  complaint that was specific and correct, and he introduces the thing that complaint did not ask
  about: a man with no body on a 64px footway, who is avoided by the meter alone. That is the
  `dog_walker` bargain, and `dog_walker` has been playtested and this has not.
- **The two new cues have been read by a rig and not by a person.** *(M32.)* The mark now comes
  down at the kerb and the badge measures the thing's own approach — both confirmed off a trace,
  which is exactly the evidence playtest 06 said was missing and exactly not a person saying the
  cue helped. The `cue` entries are what to read next: a `turn` or a `run` after one is the only
  evidence a cue was acted on. And the pram's four states have been screenshotted in every
  facing and never seen in motion by anybody.
- **A street that is solid has been walked by a rig and by nobody.** *(M34.)* About two thirds of
  the catalogue has a body now where five rows did, and day 1 went from 12.2 things that take a
  64px footway to 17.2 — with the count of events placed unchanged, so the open question is not
  density but whether being stopped reads as *cross the street* or as an obstacle course. The gap
  between a kerbed van and the frontage is smaller than the pram, which is intended and is also the
  exact shape of M19's *"no line to walk"*, a mistake a green suite and a screenshot both passed.
- **Every row now draws something of its own, and nobody has seen most of it.** *(M37 closed the
  entry that stood here for fifteen milestones: `homeless_yeller`, `busker` and `poster_crew`
  drawing one `person.svg`.)* Fourteen new silhouettes, of which the contact sheet is the only
  thing that has looked at them and only five are reachable before day 4. The two to distrust are
  the ones that are more than a picture: the **robber's two postures**, where the whole claim is
  that *waiting* and *coming* are told apart at an alley's length, and the **protest**, which is
  now a 110px wall of bodies on a crossing where it used to be a man. The crowd is still one
  `person.svg` for two hundred and forty bodies, and that is the opposite rule kept on purpose.
- **The park is 20% faster and nobody has felt it.** *(M38.)* `SLEEPINESS_CALM_ZONE_MULTIPLIER`
  10 → 12, so calm ground fills the meter in 20s rather than 24. The reasoning is sound — every
  milestone since M28 has made the walk *out* harder and left the reward at the end of it the same
  length — but the last human verdict on the difficulty is playtest 06's, three milestones and a
  denser catalogue ago, and this moves the one number that decides whether a day is winnable once
  the park is reached. It also narrows the "a calm area is more than one lap" margin in
  `docs/MECHANICS.md` from 23.8s to 19.8s against a 10.8s lap.
- **A flock has been walked through by a rig and by nobody.** *(M38.)* The gradient is measured —
  +35 through the middle, +8 eighty pixels off it, nothing at the rim — and what is not measured is
  whether eleven birds at 96px/s inside a 62px wheel read as *a flock going up in your face* or as
  a swarm of dots. It is also the only row in the game that is more than one emitter, so it is the
  only row where the cost table and the thing the player meets are computed differently.
- **There is no audio at all.** Less urgent than it sounds, given the rule above: audio is
  redundancy, so the game must already be fully playable without it.
- **Dev flags are always on.** `--seed`, `--day`, `--spawn`, `--follow`, `--meters`,
  `--overview`, `--day-length` and (in `auto_screenshot.gd`) `--screenshot`, `--after`,
  `--walk` ship in the build and live in `main.gd`. They should be gated behind a debug
  build before release.
- **There is no main menu.** There is a **title screen** since M38 — the doorstep with the traffic
  and the events running behind it and nobody in it, `space` to begin, and a finished run goes back
  to it — but it is a title, three lines of controls and two keys, not a menu: no options, no seed
  box, no load game. `Esc` opens a pause screen (M33, and it did not actually open until M36), `R`
  inside it starts the run again and `Q` quits; the between-days summary is still its own kind of
  pause, and the pause opens over it. What M38 closed is the *dead end* — the ending screen said
  `esc to quit`, `Esc` opened the pause, and the pause offered `Esc` and `Q`, so the only way out of
  a finished run was to close the window.
