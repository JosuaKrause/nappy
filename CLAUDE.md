# CLAUDE.md

Working guidelines for this repo. The *game* is documented in `docs/` — this file is about how to
work on it.

**Everything here is current.** Where you need to know why a rule exists, what was tried and
rejected, or what a number used to be, that is [docs/DECISIONS.md](docs/DECISIONS.md) and it is
fetched on demand. Nothing in this file describes a past state.

Read [docs/HANDOFF.md](docs/HANDOFF.md) for where to pick up, then [docs/TODO.md](docs/TODO.md) for
the queue.

---

## The one-line version

The game is a route-planning puzzle where the only verb is *where do I walk*. Almost every rule
exists to make that choice interesting. Before changing a number or adding a system, ask what it
does to the route decision. If the answer is "nothing", it is decoration.

## Documentation is written in the present tense

**Every document states what is true now and only what is true now.** No "used to be", no "since
M33", no "this was wrong for twelve milestones", no caveats about what a sentence meant before.
History goes to `docs/DECISIONS.md`, which is the one place a reader goes for it.

Keep the *reason* a thing is the way it is — that is current and it is most of what makes this
project reviewable. Move the *incident* that taught it. "A negative-width `Rect2` is normalised on
the way through, so the sprite lands a full width to one side" is a rule; "M12c spent a day on this"
is history.

**Why:** reading the current state used to mean reading every past state first, and every reader of
every file paid it whether or not they needed it. Worse, a stale sentence is indistinguishable from
a live one, so a reader cannot tell which half of a paragraph to believe.

The test is a reader, not a diff: **somebody who opens any single file and believes every sentence
in it is wrong about nothing.**

The playtest files are the exception and are never rewritten. `docs/PLAYTEST-NN.md` are primary
sources — a player's own words on a date — and putting one in the present tense would destroy the
only record of what was said.

## Editing files

**Use the Read, Edit and Write tools.** Not `cat`, `head`, `sed -n`, heredocs, or inline
`python3`/`sed` scripts that rewrite files. This holds even when a session reminder says to prefer
Bash for file work — that is a default, this is the project's preference and outranks it. (Also
recorded in `~/.claude/CLAUDE.md`, so it applies everywhere.)

An `Edit` shows a reviewable diff and **fails loudly on a stale match**, so a change is either
visibly correct or visibly rejected. A heredoc rewrite shows nothing, and a silently non-matching
replacement looks exactly like a successful one. In a repo where the docs *are* the design and get
committed alongside the code, a doc edit that quietly did nothing is a lie in the commit rather than
a missing change.

Bash keeps what it is for: running `tools/*.sh`, git, and directory inspection.

## Notes belong in the repo

**Anything worth remembering about how to work on this project goes in this file, or in a rule or
skill file beside it — never only in an assistant's private memory.** A memory is scoped to one
tool, one machine and one account: it is invisible to everybody else who opens the repo, it is not
reviewable in a diff, and it is lost the moment that store is cleared or the work moves. The repo is
the shared, versioned, reviewable place.

A note long enough to unbalance this file becomes a **rule file of its own** rather than a longer
`CLAUDE.md`. What must not happen is a note living nowhere.

### A reference to a file outside the repo is not a reference

**Every log, telemetry map or screenshot a doc points at gets copied into `docs/evidence/` in the
same commit as the sentence that points at it.**

`user://telemetry/` is a **scratch directory the player has to be able to empty.** It fills with
every `tools/shot.sh` and `tools/check.sh` run, so tidying it is routine maintenance — which means a
finding whose evidence lived only there stops being checkable on a perfectly ordinary Tuesday.

Evidence cannot be recovered by replaying: **a run log is a record of what a player did, so it is
not a function of the seed.** Regenerating gives a different run with the same city. Keep the
original filename; it carries the timestamp, the seed and the commit, which is most of what makes
the file worth having.

### Write the feedback down with all of its detail, before doing anything about it

**Every piece of playtest feedback goes into `docs/PLAYTEST-NN.md` in full — the player's own words,
and every specific they gave — before a line of code is written.** Then it becomes a `docs/TODO.md`
item, and only then does it get implemented.

The failure mode is specific and it is not laziness: a finding arrives as *a complaint plus a
design*, the complaint is the part that is easy to restate, and the design is the part that took the
player thought. **Record the design even when you are about to fix the complaint**, and record it
even when you disagree with it — a note saying "asked for X, built Y instead, because Z" is a
decision somebody can overturn. Nothing else is.

The test of whether it was written down is not "did I mention it" — it is whether somebody opening
the repo cold could **build the thing that was asked for** from what is on disk.

### Never silently overturn a decision the player took

**Recording a request is not the end of the obligation to it.** Once something has been asked for,
the only ways it may stop being true are: *it gets built*, *the player changes their mind*, or *they
are asked and they agree*. **There is no fourth way.** If a milestone is about to drop, narrow,
park, invert or reinterpret something the player asked for — **stop and ask first**, in the session,
before writing the code or the status line. Carry on with everything the answer does not block, and
put the question where they will see it.

It has to be a rule because overturning never looks like overturning from the inside. It arrives as
an *argument*, and the argument is usually a good one — measurement said the opposite, two
instructions conflicted, the thing cost more than it was worth. All of that is worth writing down,
and **none of it is a decision this side of the conversation gets to take.** The player is the only
one who knows what they wanted it for.

Three shapes it takes, each worse than the last:

- **Parking something and erasing who asked for it.** The parking then reads as justified to
  everyone who comes after, and no one will ever check.
- **Letting a later instruction repeal more than it said.** Two instructions in tension is the exact
  case that has to go back to the player, because only they know which one was load-bearing. **When
  a new instruction contradicts an old one, the overlap is a question, not an inference.**
- **Answering the complaint and dropping the design.** The complaint is the part that can be
  verified fixed, so it is the part that survives.

**When you do ask, ask with the work already done up to the fork** — what was asked, what it now
collides with, what each branch costs, and which you would pick. A question that hands the whole
problem back is its own kind of failure.

When a decision *is* overturned with agreement, the note says so in the player's words: `asked for X
· overturned to Y on <date>, because Z`. A status line that cannot name who agreed is a silent
overturn that has not been noticed yet.

### A parked option comes back as a question, never as a plan

**A future complaint is not advance approval of the fix somebody parked against it.** A complaint
says the design has a problem. It says nothing about which parked option is the answer, or whether
the answer is any of them, and the player who says the sentence is describing an experience rather
than picking off a menu they cannot see.

So when parking something, record **what it was and why it was not taken**, and record the symptom
as *what would make this worth discussing again*. Never as what would authorise it.

### Writing it down is half the rule. Reading it back is the other half

**The first tool call of a design task is a search, not a plan.** Search `docs/TODO.md` and the
playtest files for the thing being asked — not for a milestone number, for the *words*. `grep` the
noun. A request that has been made before is already written down here in the player's own sentence,
usually with the measurement, the constraints and the three things to get right sitting under it.

**And search the docs before believing the code.** The code is evidence of what was *built*; it is
never evidence of what was *agreed*. A decision can sit written down and unbuilt for twenty
milestones, and a session that checks only `src/` will confidently tell the player that their own
decision never happened.

Two costs, and the second does the damage:

- **The player pays to say it again.** Every re-report is time spent describing something the
  project already agreed to, and it is indistinguishable from the project not having listened.
- **A question goes back that the repo could have answered.** Asking is right when the answer does
  not exist; asking when it does is the overturn rule's shape in miniature.

When a finding turns out to be a re-report, say so in the entry and close it *from* the older one
rather than writing a second design for it — two entries for one request is how the next reader
loses the half with the measurement in it.

## Names are content, never identifiers

The mother and the baby have names — see `docs/NARRATIVE.md`, which is the one place that says what
they are. **Nothing in `src/` may be named after them.** No `hal.gd`, no `var wren`, no
`WREN_CRY_THRESHOLD`.

**Why:** a name can change at any time, and a name that has reached an identifier changes with a
rename across every file that mentions it — a diff nobody can review for anything else, on a
decision that was meant to be cheap to revisit. The code calls them what they *are* — `Stroller`,
`Baby`, `player`, `mother` — which is stable under every renaming the narrative might want. The
names belong in the writing: dialogue, the HUD's own strings, `docs/NARRATIVE.md`.

The same holds for anything else the fiction may rename: the city has no name for the same reason.

## Verification loop

Run all three before committing. They are fast and they each catch a different class of bug.

```sh
./tools/check.sh              # imports, boots the project, fails on any script error
./tools/test.sh               # the full headless suite, ~200s
./tools/test.sh crowd events  # just those suites, in seconds — for the inner loop
./tools/shot.sh out.png 3     # renders 3 seconds of real gameplay to a PNG
./tools/telemetry.sh          # what the last run actually did, in order
```

A filtered run prints `PARTIAL RUN` under its count and is not a green build. Commit on the
unfiltered one.

**A green `test.sh` says nothing about whether a *run* behaves.** Every run writes an ordered trace;
if you changed anything the player experiences, play a minute of it and read the log back. Defects
found only that way include a `run` entry claiming a six-hundred-pixel event was "in reach", and a
meter breakdown reading `crowd 0.0, events 0.0` while the meter climbed, because the player was
doing it to herself with the run button and nothing said so.

**Where a run cannot be played, walk a rig and read the meter.** A throwaway `tests/test_zz_*.gd`
that prints numbers and is deleted before committing is the headless stand-in for the minute of play
the rule above asks for — and the numbers it prints are how a balance constant gets set, rather than
derived. It is the only thing that catches a pedestrian being ploughed along the pavement in
permanent contact, or a contact radius that leaves **no line to walk** on a two-tile pavement.

**A rig that steps the parts is not running the whole, and the gap is silent both ways.** Several
suites walk the crowd by hand — `for agent in crowd.agents(): agent._process(step)` — so that a
minute of traffic does not take a minute. That skips the frame *around* the agents:
`Crowd._physics_process`, which resolves the queue and rebuilds `TrafficIndex`. `claim()` is written
to outlive one frame and nothing bounds it, so with nothing rebuilding, every recycle stays. **When
a rig drives a subsystem by hand, ask what the engine was doing around it** — and if the answer is
"keeping something bounded", the rig is not slow, it is wrong. `Crowd.step()` is the whole frame and
is what a rig calls.

**A green `check.sh` says nothing about whether the game looks right** — headless runs never call
`_draw()`. Real bugs found only by opening a screenshot: building extrusions overhanging every
sidewalk, zebra crossings rendering as visual static, a fire always spawning against the map wall.
If you touched anything visual, take a shot and actually look at it.

**A screenshot of a standing player is a screenshot of almost nothing.** The crowd and the events
are built around her, and the director only puts something in front of her while she is going
somewhere — so use `--walk north|south|east|west`, which holds a direction down for the whole run.
`tools/shot.sh` forwards every dev flag.

**`--flee` is how the one encounter with a right answer gets played.** A rig that can only hold a
direction can only ever demonstrate the wrong answer. `--flee [delay]` turns round and runs when
something starts chasing her, and the delay is the axis worth measuring: what the right answer costs
when it is given late.

**Nothing in the suite or in a screenshot presses a key on its own, so use `--press`.** A green suite
and a screenshot both pass a pause screen that never opens. Note what its first version got wrong:
`Input.action_press()` sets the **polled** state and nothing else, which is right for `--walk` and
useless for anything answered in `_unhandled_input`. Push a real event with `Input.parse_input_event`.

**And a bare key is not an action.** `--press` pushes an `InputEventAction`, which reaches actions
in the input map and nothing else — while a screen's own shortcuts are usually read as **keycodes**.
`--press key:r 3.5` reaches those, and the flag may be repeated, because one tap can only ever
photograph one screen and what usually needs checking is a sequence. The one thing it cannot do: `R`
reloads the scene and the reloaded scene re-presses, so a rig restarting the game loops for ever.
Read the boot lines rather than waiting for the PNG.

**Where a cue cannot be triggered on demand, relax its condition, look, and put it back.** The
screen-edge badge needs something lethal off-screen and closing, which is not something a six-second
screenshot can be asked for. Forcing it on for one shot is the only thing that finds a badge
colliding with the excitement meter or an icon squashed by a square box.

**`--after` on the screenshot tools is in seconds, not frames.** The windowed build draws ~110fps,
so a frame count is quietly useless.

**`--spawn corner:nw|ne|sw|se`** points the camera at the place where two border bands meet. It
stands a couple of tiles inside the corner, on the pavement — `_nearest_walkable` will otherwise
happily leave her on the boundary carriageway.

## Git workflow

- **One branch per milestone**, named `feature/<thing>`, merged to `main` with `--no-ff`. The merge
  commits are the project's spine; keep them.
- **Delete a branch as soon as it is fully merged, always, without being asked.** The merge commit
  is what the project keeps; the branch pointer is scaffolding. Left alone they accumulate one per
  milestone, and the cost is not clutter — it is that `git branch` stops being able to answer the
  only question it is good for: **is there work that is not on `main`?**

  ```sh
  git branch --merged main | grep -v '^\*' | grep -vw main | xargs git branch -d
  ```

  `-d` and never `-D`: `-d` refuses anything not merged, so the command cannot lose work, and a
  branch it refuses is exactly the one worth looking at. (On macOS `xargs` has no `-a` — feed it by
  pipe or `< file`.)
- **One commit per `TODO.md` item, inside that one branch.** A milestone is a list of things that
  were decided separately and are each true or false on their own, so each one gets a commit that
  can be read, reverted or bisected by itself.
- **Commit before stopping.** Work that is finished and green does not sit in the working tree
  waiting to be asked about: an unfinished milestone is a branch with commits on it, not a dirty
  tree. The local repository is the assistant's to manage — branch, commit and merge without asking
  each time.
- **And that includes a session that only writes docs.** A long design conversation produces the
  most valuable and least recoverable thing in this repo — a brief in the player's own words, and
  the reasoning around it — and it is exactly the work that feels too unfinished to commit, because
  the design is still moving. Commit each piece as it is settled.
- **Commit the docs in the same commit as the code.** `docs/` is not a report written afterwards, it
  is the design. If an implementation contradicts a doc, the doc is wrong and gets fixed in that
  commit.
- Commit messages explain **why**, and say what was tried and rejected. When something was
  discovered mid-implementation, say so — that is the part that is not recoverable from the diff.
- Never commit `.godot/`. It is gitignored, which means a fresh clone has no `class_name` registry
  and every typed reference fails to parse until `check.sh` runs the import pass.

---

## Godot 4.7 / GDScript gotchas

These are not obvious and the engine does not warn about most of them.

**`set(key, value)` silently drops a type mismatch.** Never build typed objects from dictionaries —
every `Array[int]` field comes out empty with *no error anywhere*. Use an explicit factory function
with named parameters.

**Passing an untyped `Array` into an `Array[T]` parameter leaks at shutdown.** The coercion at the
call boundary retains the arguments; you get "N ObjectDB instances were leaked at exit". Declare the
real element type at the call site.

**Some warnings are errors by default.** `var x := some_variant` ("the variable type is being
inferred from a Variant value") fails the parse outright. Annotate instead: `var x: int = ...`. This
does not show up until the project actually boots, which is why `check.sh` exists. The form that
catches people is `var x := load(path).instantiate()`, because it reads as obviously typed and is
not — and in a *test* it fails at load time, so the suite prints nothing at all and looks like it
hung. Write `var scene: PackedScene = load(path)` and `var node: Node = scene.instantiate()`.

**A runtime error inside a test suite hangs the runner instead of failing it.** `run_tests.gd` calls
each suite's `run()` synchronously and then `get_tree().quit()`. An error aborts `_ready()` before
the quit, so the headless process sits there forever printing nothing. **A test run with no output
at all means an error in a suite, not a slow suite.**

**A *parse* error does the same thing and is easier to cause**, since `_discover` loads every suite
before running any: a bad indent in one file takes the whole run down with `Failed to load script`
and then hangs. The way to see either is to stop piping the run into `tail` — `tail` prints nothing
until EOF, so a hung run and a silent one look identical. Redirect to a file and read it; the
message is usually on line four.

**`--script` skips autoloads.** The test suite runs as a *scene*
(`godot --headless --path . res://tests/tests.tscn`) because every test needs `Tuning`.

**An autoload name cannot also be a `class_name`.** That is why shared enums live in
`src/game_enums.gd` rather than on `GameState`.

**`SomeNode.new()` does not get the name `SomeNode`.** `Camera2D.new()` is named `@Camera2D@41`, so
a `@onready var _camera := $Camera2D` in a test rig silently fails. Set `.name` explicitly when a
node is looked up by path.

**A cross-script enum is not the same type as itself.** `static func f(side: Side)` in one script,
called from another where `x` came from `OtherScript.Side`, fails to parse: *"argument 2 should be
Side but is StreetNetwork.Side"*. Widen the parameter to `int` and say why in a comment.
`StreetNetwork.beside_block()` is the one place that does.

**Nodes are not refcounted.** A test double extending a `Node` class must be `free()`d by hand or it
leaks. `RefCounted` doubles do not.

**A negative-width `Rect2` does not flip `draw_texture_rect`.** It is normalised on the way through,
so the sprite lands a full width to one side — which looks like art sliding off its own shadow, not
like a failed flip. Mirror with `draw_set_transform(at, 0, Vector2(-1, 1))` around the anchor
instead. `Sprites.draw_standing()` is the one place that does it.

**`process_mode` is inherited, so one `PROCESS_MODE_ALWAYS` exempts a whole subtree.** `main.gd`
sets it on itself so Esc still quits while the summary has the tree paused — and every descendant
defaults to `PROCESS_MODE_INHERIT`. `main._pauses_with_the_game()` is called on every node that is
the game rather than the frame around it. **If you add a node under `Main`, it needs that call**,
and nothing warns you.

The title screen needs the split the other way round — the **city** running while the **day** does
not — so `_city` goes to `ALWAYS` for the duration and `_player` is pinned to `PAUSABLE`, because
she is a child of it and would otherwise inherit the exemption. Anything that wants the same trick
names its own exceptions the same way; there is no "pause everything except" switch and there should
not be one.

**Y-sorting compares origins, so a thing whose mass extends away from its own origin sorts wrong.**
A `Building`'s origin is the south edge of its lot and it is drawn a whole block north of there.
**Before reaching for a better comparison, ask whether the two things can ever legitimately be on
opposite sides of each other.** Buildings cannot — no lot tile is walkable — so they are a layer of
their own and sort against nothing.

**A paused `Camera2D` with smoothing on never arrives.** `position_smoothing_enabled` is applied in
the camera's **own** process callback, so a camera that is `PAUSABLE` under a paused tree stops
following the thing it is attached to and sits wherever it last was — which on the first frame of a
run is the world origin, clamped to the corner of the boundary wall. `Stroller.stand_aside()` puts
the camera on `ALWAYS` for the duration. The thing that looks like the cause and is not: **hiding a
`Node2D` does not deactivate a `Camera2D` under it.**

**A `Dictionary` keyed by `Vector2i` hashes a Variant on every lookup.** Fine for a set of today's
closures; not fine for a flood fill, where it costs about 3.6× a flat `PackedInt32Array` indexed by
tile. Two things that come with it: **paint the blocked set into the grid before the sweep** rather
than asking about it per neighbour, since building a `Vector2i` four times per tile is most of what
is left; and **write the four neighbour steps out** rather than looping an offset array, because the
loop's own bounds test costs more than the arithmetic it guards. Same shape one level down: a
`Tile.is_walkable()` call per tile becomes a `PackedByteArray` indexed by tile type, built *from*
`Tile.is_walkable` so it stays the one place that decides.

**`_draw()` is retained.** It re-runs only on `queue_redraw()`, so an expensive one-off draw (the
10k-tile city ground) is fine, but anything animated must call `queue_redraw()` itself.

**`move_and_slide()` owns `velocity`, so do not put anything else in it.** Folding a deflection into
`velocity` before the slide means `is_idle()` and `run_excess_ratio()` — the only two questions the
baby asks the rig — start answering for the crowd rather than for the player. Restoring `velocity`
afterwards is worse: it throws away the slide's own correction, so walking into a wall stops reading
as idle and starts making sleep progress. A second displacement goes through its own
`move_and_collide()`, which respects walls and touches nothing.

---

## Code style

Match what is already there rather than importing habits from elsewhere.

- Tabs for indentation. Wrap at ~96 columns.
- `##` doc comments on every class and on any function whose purpose is not obvious from its name.
  Class doc comments say what the thing is *for*, not what it contains.
- **Document the why and the edge cases; do not restate the implementation.** The code is right
  there. Where a number was tuned against something, keep the *relationship* — "above the 7.7/s
  decay on the ground it stands on" — and let `docs/DECISIONS.md` hold the story of how it got
  there.
- Section dividers inside longer files:
  `# ---------------------------------------------------------------- drawing ---`
- **Comments explain why, never what.** `# Skip the stretch inside an intersection, where a centre
  line makes no sense.` is worth writing; `# loop over tiles` is not.
- Leading underscore for private members and methods. Godot lifecycle methods (`_ready`, `_draw`,
  `_process`) are the exception and are not private.
- Prefer a named constant in `Tuning` over a literal anywhere gameplay can feel it.

---

## Invariants — do not break these without a deliberate decision

**Determinism.** Nothing gameplay-relevant may call the global `randi()`/`randf()`. Use
`GameState.city_rng()` (layout, once per run) or `GameState.day_rng(day, stream)` (per day). Pass a
distinct `stream` per consumer, or two systems asking for "the day's RNG" start from the same seed
and their first rolls move together. Purely cosmetic randomness may use the global RNG and must stay
away from anything touching the meters.

**And one stream shared by several *phases* is the same bug with a longer fuse.** A phase whose
consumption can vary gets its own stream (`EventScheduler._stream(base, salt)`), and inside the
recurring fill each attempt gets one too, because `_place_one` re-rolls a variable number of times
and returns early when a candidate is perfect. Otherwise anything that changes how much an earlier
phase draws moves everything after it, and a retried day is a different day.

What is deliberately **not** closed: a scar, or a spent one-shot's route, genuinely frees ground, so
placements rejected against it now fit. The composition of the day is identical and a handful of
route rows start a few tiles along the same street — which is the run's own history showing through,
and is the answer that should show through.

**The falloff has a shoulder, and the shape is a design decision.** `Tuning.falloff` is `1−t²`
between the inner and outer radius, not `(1−t)²`. The squared-complement form puts a quarter of the
intensity at the midpoint of the band and six percent three quarters of the way out, which makes
three quarters of every radius in the game free and an event a thing to bump into rather than a
thing to route around. Two consequences:

- **The telegraph fairness contract does not care.** It is stated over *distance* — how far she has
  to walk to be outside the radius — so what she pays while inside one is not its business. Do not
  "fix" the contract when the shape changes.
- **The crowd does not want it.** A field that bites from a distance is right for an authored event
  and wrong for one of two hundred and forty bodies, which is supposed to be inaudible from across
  the pavement. The crowd pays it back in *radius* rather than in intensity, so a close pass costs
  what it always did.

**Excitement is a pure query.** Events never push a value at the baby. `Baby` asks the
`WorldContext` for the total at its position, and the world sums `contribution_at()` over live
instances. This is why events compose by simple addition, there is no ordering to get wrong, and an
event can be tested without a scene. Do not add a code path that writes to `Baby.excitement` from
outside. The crowd is summed the same way and for the same reason — `City.total_excitement_at` adds
the two and nothing else.

**A contact startles the person she walked into**, and that is how a collision avoids pushing. The
jolt is a decaying source on that agent's own `contribution_at()`, so a bump is summed exactly like
the body it came from and a crowded pavement composes by addition like everything else. Anything
else that wants to "add excitement" should find a body to put it on rather than a third summand —
and if there genuinely is no body, that is a design conversation, not a plumbing one.

**Sampling a tile grid by stepping world points aliases, and it aliases where it matters.** Walk the
**tiles** — `world_to_tile` once, then integer steps — whenever the question is about tile types
rather than about distance. Start at step zero, too: a car's own tile is the difference between "not
there yet" and "already across". Probing `position + forward * step * TILE_SIZE` is correct almost
everywhere and wrong at exactly one place: a car stopped at the stop line is a few pixels from the
paint, so both neighbouring samples miss the zebra.

**A placement is not a separation, and the separation must not be doing the placement's job.**
Front-to-back resolution **compounds**: the shortfall a car sees is its own overlap plus everything
already moved ahead of it, so a bunched queue shunts the rearmost car several lengths backwards in
one frame. A car choosing an arm of a junction has to look before it commits. Three things to carry:

- **`TrafficIndex` is the look, and it is a frame stale on purpose.** A car covers three pixels in a
  frame and the question is about a car's length.
- **Two placements in the same frame cannot see each other**, and that is not a rare case —
  recycling is what happens to every car that leaves the box, and they all aim at the same entry
  band. `TrafficIndex.claim()` is the smallest thing that closes it.
- **A retry is not a guarantee.** Six re-rolls into a busy lane all miss about once a minute.
  `_join_the_back_of_the_queue()` is the fallback, because behind the last car is the one place in a
  lane that is free by construction.

The one place a large correction is right is **frame zero of a day**, where the crowd is placed
without consulting itself and the first pass unpacks it. Nobody has seen a previous frame of that
street. Do not "fix" it by spacing the crowd in `start_day`: that turns a random morning into tight
platoons at minimum headway, and three balance tests correctly object.

**Separation between bodies is positional, never a force.** A brake, a repulsion, a steering weight
— all of them keep a gap that already exists and none of them can open one that does not, so two
bodies that start inside each other stay there. `Crowd._bump()` resolves the player against a
pedestrian by moving both; `Crowd.space_out_the_traffic()` resolves a lane of cars from the front
backwards. If a new pair of things must not be inside each other, move them apart; do not ask them
to want to be apart.

**The noise floor is emergent, never a constant.** A street is loud because there are people and
cars on it, which the player can see. If you find yourself adding a city-wide "background noise"
number, that is the thing this rule exists to stop.

**`Baby` knows nothing about tiles or events.** Its entire interface to the world is four questions:
`is_calm_zone`, `decay_multiplier`, `is_alley`, `total_excitement_at`. Adding an event type must
never require touching the meters.

The fourth question is worth the precedent it sets rather than the field it adds: *the ground is a
rate, not a category*. `is_calm_zone` was doing two jobs — a threshold for the sleepiness (genuinely
a yes/no) and a multiplier for the excitement decay (never was). The shape to copy is that **a new
question generalises an old answer instead of sitting beside it**. A fifth question that is a
special case of one of these four is the thing this rule exists to stop.

**The lattice is fixed; what a block *is* is not.** The street lattice, the block boundaries, the
carves and the building footprints are all fixed for the run. What may change is a block's
**purpose** — a park can be requisitioned, a commercial street can go dark, a residential block can
burn — and only ever along the arc `CityGenerator` planned for it up front. The geometry the player
learns stays true; the meaning of it does not.

**The lattice is fixed and it is not a full grid.** A four-block calm zone absorbs the streets
between its own blocks, so the city has one or two holes in it, four T-junctions per hole, and a
junction in the middle of each zone that nothing reaches. Three consequences:

- **Route redundancy is not true by construction.** A full lattice cannot be disconnected by
  removing one corridor; this one can. It is checked by search — `StreetNetwork.route_count()`.
- **The absent streets are a set, not a hole in the enumeration.** `StreetNetwork` still enumerates
  the full grid; `CityMap.absent_segments` says which of them this city does not have, and
  `CityMap.blocked_segments()` merges it with today's closures. **Every** route search takes that
  merged set — one that takes only the closures will happily route down the middle of a park and
  overstate the redundancy.
- **A block is not the unit; a lot is.** `block_plans`, `block_layouts` and `calm_blocks` are keyed
  by the block that *anchors* a lot, so a zone is one entry with four blocks of ground. Anything
  counting calm areas counts a zone once. `CityMap.anchor_of()` and `lot_rect()` are how the other
  three blocks are reached.

**An absorbed street is calm ground, not a closure.** The tiles are park and the player walks over
them — a zone is a shortcut as well as a destination. Only the *lattice* lost the street, which is
why `absent_segments` is a set of segment keys and `closed_tiles` is a set of tiles. Anything that
travels the lattice asks `CityMap.is_street()` instead of `is_walkable()`.

The half that is absolute: **no purpose change may move a walkable tile.** `tests/test_blocks.gd`
pushes every block to the end of its arc across 40 seeds and asserts the walkable set is identical
tile for tile. Per-day *closures* remain events with an `obstructs_radius`, not tile edits.

**The day is planned across the whole city; only the world near the player is built.** Every
guarantee the game makes is stated over a **day** — one usable park, two distinct routes to two
distinct calm areas, a one-shot that fires once per run, determinism from a seed — and all of them
are properties of the *plan*. `EventScheduler.build_day()` plans the entire map at dawn. What
streams is the *instantiation*: a plan becomes a node when the player is within
`EVENT_STREAM_RADIUS` and stops being one when she leaves.

Three things that keep it honest:

- **Nothing may be seen to appear.** Both radii are wider than half the viewport diagonal.
- **`EVENT_STREAM_RADIUS` must stay wider than the widest field in the catalogue**, so an event is
  outside its own outer radius the instant it becomes visible. Otherwise streaming is a way of
  dropping events on people. `tests/test_event_manager.gd` asserts it against the catalogue.
- **A spent plan stays spent, and a running one resumes.** Streaming may take a *running* event away
  and give it back; it may never rewind one that has finished, and the bookkeeping an event does
  once — a scar, a block arc — happens on its first instantiation and never again. `Planned.age` and
  `Planned.travelled` carry it over. It **resumes** rather than catching up on lost time: ageing an
  event in absentia would put back the thing streaming was built to fix, a twenty-second event that
  is over before anybody could reach it.

Do not move a guarantee out of `build_day` and into the streaming. If something has to be true of a
day, it has to be decided where the day is.

**The telegraph fairness contract.** A player who starts walking away the instant an event becomes
visible must get clear before it hurts. `Tuning.validate_event()` asserts it on load and
`tests/test_events.gd` checks the whole catalogue. A violation is a bug, not a difficulty setting.
Two documented exemptions: `AMBIENT` events (they never "appear") and `city_wide` ones (no edge to
walk out of).

An `AHEAD_OF_PLAYER` event is **not** an exemption: it has no telegraph phase the player can see
coming, so the contract is paid in geometry instead. It is sited far enough ahead that she is
outside its outer radius for the whole telegraph, and `EventDef.validate()` refuses one that
obstructs, because nothing checks a route around a thing with no tile.

**The contract is stated per event and the player experiences the sum.** At one event per block the
outer radii overlap, so walking out of one field can mean walking into another — which is the
density working, right up until the field she walks into is one of the three that end the day. So
**nothing else happens inside a lethal event's field**: a `hard_fail` event keeps its whole
`outer_radius` clear of every other event at placement, and it is the one spacing rule with no
fallback — an abduction that cannot find room is not placed. `EventScheduler._room_around()`
enforces it. If a new event ever becomes lethal, it inherits this, not just the telegraph.

**Off the day's corridor is exempt from that clearance rule, and the exemption is the design.**
There is no route she is meant to take off the corridor — the point of that ground is that she
should not be on it — so lethal fields there may overlap each other and everything else. Under the
old rule "deadly all over" was not merely hard, it was arithmetic: six lethal rows capped at three
to five, at radii of 145–380px, cannot tile anything.

The exemption is exactly the `WALL` role and that is by construction: `_copies_of` offers a wall
zero copies of any tile inside the corridor, so a lethal placement carrying that role is off the
routes or it does not exist. `EventScheduler._keeps_its_field_clear` is the one place that decides.
**What is untouched** is the telegraph contract — that one is about a single event's own geometry
and nothing here changes what an event owes the player who sees it coming.

**A lethal radius and a solid body are the same mechanism.** The player is stopped with her centre
`obstructs_radius + PLAYER_BODY_RADIUS` from the centre of a thing, so a `hard_fail` event whose
body reaches its own inner radius can never fire at all — which is not an unfair event, it is an
event that has quietly been switched off, and that is worse. `EventDef.validate()` refuses the
arrangement on load.

**Nothing vanishes while you are looking at it.** An event that is over **leaves**:
`EventInstance._be_done()` puts it in a leaving phase where it emits nothing, cannot end the day and
carries no cue, and it moves until it is past `Tuning.OUT_OF_SIGHT` before it is deleted. Three
things to keep straight:

- **Anything `mobile` leaves at its own `speed` and needs no data.** `EventDef.departs_at` is for
  the rest — a flock, which has to fly, and a pursuer that has lost interest.
- **It is over the moment it starts leaving.** A cat that trailed its field behind it for the two
  seconds it took to reach the kerb would be a worse bug than the one being fixed.
- **Two things never leave**, and both would break something that reads the finishing position: an
  event with a `spawns_on_finish` stops where the thing it leaves belongs, and anything that was a
  *place* rather than a moment has always simply been over.

**A fairness contract stated in seconds is not stated at all.** When a contract is about a moving
encounter, **state it over distance and check it by walking**, not by asserting the numbers it was
written from. `Tuning.pursuit_standoff()` is the notice as a distance; `tests/test_events.gd` walks
the answers. Four traps inside it:

- **Clamping the approach at zero is not a stand-off.** It leaves the pursuer standing politely
  still while *she* closes the last hundred pixels and dies on the first lethal frame — the contract
  true of the thing and false of the encounter. It has to back off, and the price is the wart: a
  stand-off wide enough to be seen doing it is a dog that visibly reverses.
- **A break-off stated as a distance needs two inequalities and they fight.** "Walking cannot reach
  it inside the chase" and "running can" are the same three numbers pulling opposite ways.
  `PURSUIT_SHAKEN_OFF` ends a chase at a **rate**: the pursuer is faster than a walk and slower than
  a run by construction, so *only running can open the gap*.
- **Check it with a rig that accelerates.** A rig holding a constant speed from frame one passes
  while a player reports the encounter as unplayable, because nobody can turn round in nought
  seconds. Reversing a walk into a run takes `(WALK + RUN) / ACCELERATION`. **When a contract is
  about an encounter, put every body in the encounter into it — including the cost of the player's
  own answer.**
- **A rig that runs on a timer runs into it.** The director sites what it owes in front of the
  direction she is *actually travelling*, so a `--flee` that starts before the pursuit is placed
  puts the pursuit in front of the run. It waits for the chase.

And the open half: at the lunge she is walking *into* the thing, so the gap closes at `pursue_speed
+ WALK_SPEED` and the window to answer is about **0.2s**. A player answers during the telegraph
instead, where it is visible and closing for two and a half seconds.

**When a rule is about what the player did, state it over the player.** A proxy that is equivalent
in the ideal case is not equivalent in a street, and every measurement you take of the proxy will
agree with you. `PURSUIT_SHAKEN_OFF` ends a chase when *she* has been opening the gap — stated over
the pursuer's geometry instead, a corner, a kerb, a body in the way or a 0.37s about-turn resets it
and the dog chases somebody who is plainly sprinting.

**A pursuit has two shapes and a third state.** `charging_dog` is a **moment** — the director sites
it in front of her and the chase is all of it. `EventDef.pursues_within` is the other shape: a thing
that is *somewhere*, that can be seen and priced and routed around, and that becomes a chase if she
walks up to it. Two things about the waiting state are easy to get backwards:

- **The clock starts when it notices her**, not when the day put it there. A telegraph that ran at
  dawn four streets away arrives with no notice in it at all.
- **Its notice does not damp what it emits.** `TELEGRAPH_INTENSITY_FRACTION` means *this has not
  started yet*; a man standing in that alley has started, and what has not started is the lunge. It
  is the one telegraph in the game that does not quieten the thing it is warning about.

And a trigger at or past the break-off distance is a pursuit that loses interest the instant it
starts — she is already standing where "it has lost her" means, so walking away works, and walking
away is the one answer that must never work. A break-off stated as a rate cannot reproduce it at any
trigger distance.

**A fixture can move, and `EventDef.paces` is how.** A **beat** rather than a journey: it walks its
route, turns round at the ends, and neither departs nor expires. A stationary source is a fixed
price on a fixed patch of ground — a line you draw once and never think about again — and a man
pacing two hundred and fifty pixels of footway is a timing problem on top of a routing one. The
price is the body: anything mobile is exempt from the rule below, so making something pace **takes
its `obstructs_radius` away**, and what has to replace it is intensity.

**Anything that stands still is solid at the width it is drawn.** `obstructs_radius` is **half the
silhouette** and not a balance value — `EventInstance._draw_spread` draws a blocking object at
exactly the width it obstructs for the same reason in the other direction. Three exemptions, each
written down in `docs/EVENTS.md`, "Solid things are solid": anything **mobile** (a moving wall pins
her), anything `AHEAD_OF_PLAYER` (`validate()` refuses it), and anything with no silhouette.
`tests/test_events.gd` walks the catalogue and requires everything else to have one.

The knock-on to watch: a body is a **route** cost. `Tuning.OBSTRUCTION_A_PARK_CAN_HOLD` is the rule
that used to read "nothing that obstructs" restated as what it always meant. **If a rule tests
`obstructs_radius > 0`, ask whether it means *has a body* or *closes ground*.**

**The traffic fairness contract.** A car is lethal and is **not** an event, so `validate_event()`
never sees it. `Tuning.validate_traffic()` is its equivalent and runs on boot. Two things stand in
for the telegraph: the painted carriageway, which is permanent and learnable and which she chooses
to step onto, and the horn, which must be long enough to walk the whole width of it with the doubled
hard-fail margin. If anything else ever becomes lethal without being in the catalogue, it needs its
own stated contract in the same place — a hard fail with no written contract is a bug waiting to be
called a difficulty setting.

**The main road replaces the courtesy with a clock, so the clock is the contract.** Traffic on the
spine does not give way at a zebra — what stops it is the light — so the thing standing between her
and a hard fail is the length of the **side street's** green, and `Tuning.validate_signals()` states
it in the same shape: long enough to walk the carriageway with the doubled margin. Two things are
easy to get backwards. The green that matters is the *other* arm's, because she crosses the main
road while the main road is stopped; and the amber is a **clearance** period rather than a warning —
the crossing arm stays red through it and a car too close to stop is counted as already in the box —
so lengthening it buys her nothing and lengthening the side green buys her everything.

**A lane is a queue; a junction is a box.** `Crowd.give_way_at_junctions()` is the rule and four
clauses of it are load-bearing:

- **Only crossing traffic conflicts.** Two cars meeting head-on are in different lanes and pass.
- **A car that cannot stop is counted as already in the box**, not asked to brake — the zebra's
  commit rule, because braking too late means stopping *in* the thing.
- **Nothing enters a box it cannot leave.** Without this one clause a single backed-up queue takes
  the streets either side of it with it.
- **Nearest first, then right before left.** Distance alone leaves a symmetric arrival undecided and
  right-before-left alone deadlocks four cars in a ring; in that order there is exactly one winner
  per box per frame. A light overrides the whole negotiation where there is one.

The collision that gets through is deliberate and is **not** a catalogue row: it startles the cars
it happened to, which composes by addition like every other body. An event nobody meets in a run is
a silhouette and a fairness contract spent on decoration.

**A signalled grid has a capacity, and the population has to respect it.** Signals with arbitrary
offsets stop a car at *every* junction, so the cycle is derived from the block spacing
(`SIGNAL_PROGRESSION_BLOCKS`). And junction control gives the road a throughput it did not have, so
the car population is a number about capacity as well as about noise: a car waiting at a light
beside you is louder for longer than one going past.

**The green wave serves one direction, and a two-way wave is not available at any setting of this
constant.** With offsets `j·travel`, a car going *with* the wave holds its phase exactly, and one
going *against* it advances `2·travel` per junction, which is only constant if the cycle **divides**
`2·travel` — true at `blocks = 1` and nowhere else. That needs `cycle = 2·travel` = 5.7s, and the
side green plus its ambers is 9.0s before the main road gets a second. The asymmetric offset is the
*best* answer, not a compromise: `θ = travel` gives 72% overall, and `θ = cycle/2` — the
symmetric-looking one — puts both directions on a three-phase sweep at 47%.

Two things to carry, because the shape recurs:

- **An identity is not the property.** Asserting `cycle / travel` is an even multiple is *true* and
  pins nothing, because it is not the condition the sentence beside it claims. `tests/test_crowd.gd`
  walks a car down the platoon instead.
- **The stopped fraction is not the speed spread.** `CAR_SPEED` is 130–185 against a wave tuned for
  157.5, so a slow car drifts 0.6s per junction — but a car lives 3.8 junctions on the spine and
  needs 13 to drift out of a green band, and the **fast** half stops more than the slow half. Drift
  is real and it is not the mechanism. The mechanism is that the main arm is red 53% of the cycle
  and only half the traffic gets the wave.

**A gap is a snapshot, and *do not block the box* has to know the queue is moving.**
`Crowd._can_clear_the_box` credits the leader's speed for one `CAR_HEADWAY_TIME` — the same horizon
the car-following rule already trusts it for — but **only when the leader is already past the far
side**. Crediting it unconditionally lets a car follow its leader *into* the box. **Ask what the
number you are crediting is a fact about**: a leader inside the box is the obstacle, not evidence
about the road beyond it.

**Every day stays winnable, and it always has somewhere else to go.** The scheduler guarantees one
unspoiled park and a walkable route from home to a park; on top of that, `ClosurePlanner` keeps **at
least two distinct calm areas reachable** (`Tuning.MIN_CALM_AREAS_REACHABLE`), checked before
accepting each closure rather than repairing the day afterwards, so a bad set never exists even
briefly. Anything new that closes a street must go through it — `tests/test_routes.gd` will fail the
build if it does not.

**Two areas is the count and reachability is the strength.** Two *areas* is what stops a day
arriving where the only calm left is the one this morning spoiled; dropping to one reachable area is
an unwinnable day. What edge-disjointness used to stand in for now has its own statement: by Menger,
two routes meant *no single street is a cut*, so `tests/test_routes.gd` asserts that sentence
directly, about the city rather than about each area — **no one street cuts off all the calm.** A
second route to any given area is an offer the day makes when the map allows one (`RouteTree`), and
a wall is placed off the day's tree, so what protects the calm is *where a closure goes* rather than
how many ways round it there are.

Two exemptions, and they are the same exemption at both ends of the journey: **a doorway is not a
route.** The street outside the home is never closed (the home is a notch with one exit), and an
area is reached by arriving at *either end* of a street it opens onto, so a courtyard with one
archway is still reachable two ways.

**The words for placement are fixed, and there are three axes rather than one.** The full table is
`docs/CITY.md`, "The words for it". A blocker has a **permanence** — `hard` (pruned into the layout,
whole run) or `soft` (placed for one day); an **effect** — `lethal` (ends the day), `impassable`
(stops passage, does not kill), or `costly` (passable at a readable price); and a **role**, which is
what the scheduler placed it *for* — `wall` (bounds the corridor), `friction` (sits inside it), or
`set piece` (placed so she meets it). The **corridor** is the ground a day's routes run through. Do
not reintroduce the bare word "blocker" for any of these: three questions answered by one word is
why this design had to be restated three times.

**A closure is silent, and it is the only thing that moves where the player may walk.** Closures
change the shape of the route and contribute nothing to the meter — the noise of a street is the
crowd, the danger is the events, the shape is the closures. A noisy roadworks already exists as the
`construction` event. Do not let a closure emit; it would be a third thing for
`City.total_excitement_at` to sum, and that list is exactly two long on purpose.

This is **consistent** with the diversion design in `docs/CITY.md`, "Guiding her to the calm". A
road closure there is *"not lethal but prevents full access"* — an absolute stop that does not kill
and does not shout. The things that guide by being **expensive** rather than by being impassable are
ordinary catalogue events, and they already emit. What diversions ask is that closures and events be
**placed to point somewhere**, which is a scheduler decision and not a change to what a closure is.

**No circles around entities.** *(Standing decision. Do not add one, and do not reach for a ring
when something new needs signalling.)*

> How dangerous a thing is has to be visible from looking at **the thing**.

A ring communicates a falloff radius, which is a number. A silhouette communicates a threat. The
vocabulary is in `docs/EVENTS.md`, "The visual vocabulary": the **entity itself** carries most of
it; a **caret above the entity** for anything worth changing your route for, amber for *go round it*
and doubled deep red for *it ends your day*, flashing while it has not started yet; a **badge at the
screen edge** whenever something lethal or faster than a walk is off-screen and closing **under its
own steam**, carrying its own silhouette so it says what is coming rather than that something is;
above the **player** a flashing exclamation mark for a soon-to-be-bad spot, doubled and red for
danger already on her; and over the **pram**, the only cue that is not about the world — four states
of the baby herself. Nothing draws a field.

Four rules that are easy to lose and are the whole reason it is better than the rings:

- **The entity carries most of it, so one picture per row.** **No two rows share a look, no two
  looks share a silhouette**, `EventInstance.icon_for()` is the single table, and there is no
  generic to reach for. A *category* in an enum is a list waiting to happen: five categories once
  drew sixteen of the twenty-eight visible rows between them, which cost real findings — a player
  can only say *"the robber"*, and two rows that draw the same man are one milestone spent fixing
  the wrong one. `tests/test_events.gd` holds both halves. The **crowd** is the deliberate opposite:
  two hundred and forty bodies share one `person.svg`, because a crowd is what an authored event has
  to stand out from.
- **A cue that marks everything says nothing, and a cue that marks the wrong things says something
  false.** The rule is the player's expectation, stated as an **invariant a test can hold**: **if A
  is marked and B is not, A costs more to walk through than B.** `EventDef.walk_through_cost()` is
  the order, `Tuning.MARK_WORTH_A_DETOUR` is where the line falls, lethal is marked whatever it
  costs, and `tests/test_danger.gd` asserts the monotonicity over the whole catalogue plus the two
  bounds — the whole catalogue is never marked at once, and day 1 leaves its cheap end alone.

  Two things to carry beyond that row. **The cost integral lives on `EventDef`**, because the game
  asks the question the test was asking and two copies of it is a defect waiting to happen. And **a
  colour is the wrong channel for a phase**: `EVENT_STREAM_RADIUS` is 900px and no telegraph is
  longer than 4s, so an "amber means telegraphing" rule is only ever seen on the `AHEAD_OF_PLAYER`
  rows and in play it means *near*. The flash carries the phase, because a flash is a property of
  the mark rather than of a moment she had to be present for.
- **The mark breathes**, tracking current emission, which is the one thing the ring did that a
  discrete symbol does not get for free. Without it a pulsing event stops being something to time a
  pass through and becomes something that hurts at random.
- **A cue is a claim about a *moment*.** **A cue is lowered by the system that can see its
  condition**: `Stroller.warn()` takes a source and `stand_down()` lowers only that source's own
  mark, so a hold that bridges a gap in the danger does not also bridge the danger being over. And
  **measure the thing, not the gap**: the badge's closing speed is the event's own approach with the
  player held still, because a rate that includes her 92px/s is a cue for walking. Nothing in
  `tests/test_danger.gd` can see a moment, which is why the `cue` telemetry entry exists.

The exclamation mark is the load-bearing one. Every other cue says *a thing exists*; that one says
**the fairness contract is now about you and the clock has started**, which is the difference
between information and instruction. Only a `hard_fail` event and a closing car raise it. Raised for
every telegraph it would mean "a number is about to move faster" for most of the catalogue — which
the meter already says, and the player's verdict on that was *"I can just keep doing what I was
doing"*.

Its `NOW` level is two conditions: within `LETHAL_MARK_LEAD` of the radius that ends the day, **and
closing**. Note that it uses the **relative** rate where the badge deliberately uses the thing's
own: the badge says *a thing exists and is coming*, so her walking must not raise one, and this mark
says *the contract is now about you*, which is a statement about the pair of them. Two cues, two
sentences, two answers to the same-looking question — do not unify them.

**A cue that belongs to the vocabulary does not belong to a class.** The caret lives in
`Sprites.draw_caret()`, not on `EventInstance` — otherwise "the entity carries its own cue" quietly
means "the *event* entity does", and the one lethal thing in the game that is not in the catalogue
— a car — has nothing at all. If a new kind of thing needs a cue from the table, it draws the same
shape from the same place; a second hand-drawn chevron is how a deliberately short vocabulary gets
long. `Stroller.warn()` is additive rather than a setter, because the crowd and the events both
watch the ground she is standing on in the same frame and a setter lets whichever runs second clear
what the first just said. `stand_down(source)` is the smallest thing that is not a setter.

**Telemetry never touches gameplay.** No RNG, no `day_rng()` stream, nothing that changes a
placement or a roll. Where a system logs a random outcome it hoists the **existing** roll into a
variable to print it; it never adds one. That hoist is a one-line edit with a way to be
catastrophically wrong — consume one extra value from a day's RNG and every event placed after it
moves, and the determinism invariant takes every other guarantee down with it.
`tests/test_telemetry.gd` plans all fourteen days with the log off and again with it on and requires
the plans to be identical event for event.

The corollary: anything needing a per-frame check goes in `TelemetryObserver`, not in the gameplay
class. The telemetry stays out of the files that decide things, which is what makes the rule easy to
keep. See `docs/TELEMETRY.md`.

**Audio is never the only channel.** Every cue that will eventually be audio must also exist
visually, and the visual must be sufficient on its own — the game has to play identically with the
sound off. Build the visual first and judge it alone; audio is added afterwards as redundancy. An
event whose telegraph only works "because you hear it coming" is unfinished, and the fairness
contract cannot catch it: `validate_event()` checks the geometry, not whether the player was
actually warned. See `docs/EVENTS.md`, "Showing the danger".

---

## Recipes

**Change the event density** — `max_per_day` in the catalogue **first**, then
`EventScheduler.budget_for()`, because **a budget the catalogue cannot spend is not density**. Then
**measure what a day places**, over several seeds, since `_ensure_the_city_is_still_walkable` drops
obstructions that would seal the city. Do not derive the number; a temporary probe suite that prints
per-day counts takes two minutes and is the only honest way to set it. Measure four things and not
one: **placed per day**, **live inside `EVENT_STREAM_RADIUS`**, **on screen at once**, and **met on
a route** — they move by different multiples, and only the last is what the player is complaining
about.

**Two levers, and which one binds is a different answer on different days.** A *cap* binds when the
day reaches it; a *weight* binds when it does not, because a row is only offered as often as its
weight. Raising a cap the day never reaches does nothing at all.

**And the budget is per block, because the target is per block.** `budget_for()` multiplies by
`CITY_BLOCKS.x * CITY_BLOCKS.y`. A flat budget is a statement about one lattice size and nothing
else: grow the city and the same events spread thinner, which is the density silently falling while
every constant in the file still reads as correct. **Ask what a number is per.** The crowd is the
deliberate opposite — it is a population of the *field* around the player rather than of the city,
so it does **not** scale with the lattice.

**And a thing made of several bodies has to be made of several bodies.** `EventDef.flock_size`, and
three things about it are worth copying:

- **The excitement stays a pure query, one level down.** The world sums `contribution_at()` over
  instances; a flock sums over its birds. That is what makes the middle of a flock cost five times
  the rim, which is a *route* decision where one disc could only ever be a price.
- **The birds are held inside `flock_spread`, and `flock_spread` comes out of `outer_radius`.** A
  bird emits over `outer_radius - flock_spread`, so the union of eleven moving fields is inside the
  one disc `validate_event` checked. A moving emitter is only legal while that is true.
- **`lerp` cannot turn a vector round.** Interpolating a unit vector toward its opposite runs down
  the same line to zero and back out the way it came, so normalising gives the heading it started
  with. Rotate by a bounded angle (`EventInstance._steer`), and steer from *half way out*, because a
  turn costs ground.

**A moving thing has to look like it is moving.** A bob driven by **distance covered** rather than
by time, so what shows is the movement itself: a stopped thing is still and a fast thing bobs
faster. A sprite cannot swing its own legs, so a bob is what there is.

**Add an event** — `src/events/event_catalogue.gd` in the act's section, a line in the
`docs/EVENTS.md` table, and **a drawing**: an `EventDef.Look` of its own, an SVG in
`assets/events/`, a `_draw_*` in `EventInstance`, and a row in `EventInstance.icon_for()` so the
screen-edge badge has a silhouette. That last part is not optional and there is no generic to borrow
— `tests/test_events.gd` fails the build if two rows share a picture. Everything else is
data-driven. If it needs behaviour no field covers, add the field to `EventDef` and handle it in
`EventInstance` — resist adding a script per event.

Decide `spawn_mode` deliberately. `MAP` is the default and is right for anything the player could
plan around: it is a place, and finding out it is there is what walking a street is for.
`AHEAD_OF_PLAYER` is for the small number whose entire content is *the moment it happens to you* —
three seconds of cat is not a place — and it may not obstruct.

`flock_size` is the one field that changes what a row *is* rather than what it does. Reach for it
only when the event genuinely is a number of creatures, and set `flock_spread` out of `outer_radius`
rather than on top of it.

**The role is not a decision either.** `EventScheduler._role_for` reads it off the def — lethal is a
**wall** and goes off the day's corridor, a one-shot is a **set piece** and goes where every route
touches it, anything else placed on a tile is **friction** and is weighted onto the corridor — so a
new row is placed against the day's routes without anybody writing a rule for it. What *is* a
decision is `hard_fail`, which decides where the thing goes as well as what it does. If a new row
wants a role its effect does not imply, that is a design conversation and a change to `_role_for`,
not a field on the def.

`obstructs_radius` is **not** a decision: if it stands still and it is drawn, it is solid at half its
silhouette. `pavement_side` usually is not one either — `ANY` is right for almost everything, and
the two rows that use it do so because a parked vehicle belongs at a kerb and a thing that reverses
into a yard needs a wall. `departs_at` is only a decision for a **stationary** event with a
`duration`: anything mobile already leaves at its own speed, and anything without a duration never
ends.

**Change the crowd density** — `Tuning.CROWD_PEDESTRIANS_PER_ACT` / `CROWD_CARS_PER_ACT`, which are
populations of the **field** rather than of the city, and `CrowdLanes.ARTERIAL_BUSYNESS`, which is
one street's share of the three or four corridors in the box rather than of sixteen. Then **measure
it**, with a throwaway probe over a minute of a real day: how often there is a safe gap to cross the
arterial and an ordinary street, the mean wait at the kerb, contacts in a forty-second walk down a
lane centre *and* holding the midline between two lanes, and whether any two cars share a lane
closer than a car's length. Re-measuring is the only honest way to move them: a lane has a
**capacity**, and past it the arterial jams solid and no controller helps. The junctions have a
capacity too, so the car number is not only a noise number — measure the mean speed and the stopped
fraction alongside the floor, or a road that reads as "busy" in a screenshot is a car park in
motion.

**Change the street hierarchy** — `CityGenerator._assign_street_kinds` decides *where*
(`CityMap.main_road`, `CityMap.precinct_spans`); `Tuning.PRECINCT_BLOCKS`, `PRECINCT_BUSYNESS`,
`EVENT_PRECINCT_WEIGHT` and the `EXCITEMENT_DECAY_*_MULTIPLIER` trio decide *what it means*. Five
places have to agree and the failure mode of each is silent: `GroundTiles` (what it looks like),
`CrowdLanes.busyness_for` + `walkable_offsets` (who walks and drives there), `City.decay_multiplier`
(what the ground does to the meter), and `TrafficSignals.is_signalled` (whether its junctions have
lights).

The trap is scale. **There is one main road and there are two precincts, and that is the design
rather than a parameter.** One of each per *axis* is three kinds of street and no hierarchy among
them. If a kind starts appearing in every third corridor, it has stopped being a place.

**Which corridor is the main road is a fact about a city, so read it off the map.** Computing it as
`index == arterial_index(blocks)` per axis makes a phantom arterial on the other axis, weighted like
the real one but with no lights, no dark asphalt and no clearway.

**And a weighting applied inside a fixed split cannot cross it.** Cars pick their *axis* by weight,
not 50/50 before the corridor — otherwise no weight at all, 5 or 50 or any number, can put more than
half the traffic on one street. Walkers keep the even split on purpose, because a pavement has no
hierarchy for them to follow. **Ask what the weight is competing inside of**: a number that looks
like a global priority is a local one if something upstream has already chosen the bracket.

**And a retry is not a guarantee, one scale out.** When re-rolling the small decision keeps failing,
re-take the big one — a car handed a corridor whose visible stretch is all precinct re-rolls its
position and finds bollards every time, so `CrowdAgent.setup` picks another street.

**Change a balance number** — `src/autoload/tuning.gd`, which is the only place they live. Expect
tests to push back: several encode *relationships*, not values (traffic noise must stay under the
walking decay; a fast mover must telegraph across its whole radius). If a test fails, decide whether
the relationship or the number is wrong — do not just update the test.

**Add a tile type** — `GameEnums.TileType`, then `src/city/tile.gd` (walkable / calm / alley / road
/ colour), then an SVG in `assets/tiles/`, then `assets/ground_tileset.tres` **and**
`src/city/ground_tiles.gd` in the same order (the source ids are positional and mirrored by hand),
then wherever the generator should emit it.

**Add a block purpose** — `GameEnums.BlockPurpose`, the ground it puts down in
`CityMap.open_tile_for`, `Tile.is_calm` if it is calm ground, and the arcs that may reach it in
`CityGenerator._plan_arcs`. If it is calm, check `MIN_CALM_BLOCKS_AT_END` still holds — `validate()`
will tell you, on every seed, if it does not. Write it against `map.lot_rect(block)` rather than
`CityMap.block_rect(block)`, or it will be a quarter of the ground on a four-block calm zone and
nobody will notice on the lots that are one block.

**Add a closure kind** — `RoadClosure.Kind`, a row in `RoadClosure.KINDS` (name, first day, weight),
an SVG in `assets/closures/`, and a line in `ClosureMarker.CAUSES` — unless it has nothing to leave
in the road, like `CORDON`, in which case the barriers are the whole of it. Nothing else: the kinds
differ in look and timing only, because a street you cannot walk down is a street you cannot walk
down.

**Add a resistance step** — `src/resistance/resistance_steps.gd`, via the `_step()` factory.

**Add a HUD element** — `scenes/ui/hud.tscn` plus `src/ui/hud.gd`. The HUD listens to `EventBus` and
holds no reference to the world. Anything that has to *ask the world* where things are every frame
does not belong in it: `DangerEdge` is its own layer, created by `main`, for exactly that reason.

**Add a danger cue** — first read `docs/EVENTS.md`, "The visual vocabulary", and pick a row that
already exists. The vocabulary is deliberately short and adding to it is a design decision, not a
drawing one. Never a ring.

**Add a telemetry entry** — `Telemetry.note("kind", "sentence")` where the thing happens, a row in
the table in `docs/TELEMETRY.md`, and a kind reused from that table rather than a synonym for one.
It has to answer a question that is open in `docs/TODO.md` or a playtest doc; if it does not, it is
a metric and does not belong. Anything per-frame goes in `TelemetryObserver`. Read a run back with
`./tools/telemetry.sh`.

---

## Testing policy

Test what a screenshot cannot see, and screenshot what a test cannot judge.

- **Always tested:** meter arithmetic, falloff and the fairness contract, generator guarantees
  across many seeds, scheduler determinism, day outcomes, ending selection. These are the places
  where a bug is invisible until it ruins somebody's run.
- **Integration-tested against a real `City`:** anything about wiring — retirement, successors,
  scars. `tests/test_event_manager.gd` exists because a freed-node-left-in-a-list bug is invisible
  to a data-level test.
- **`tests/test_full_run.gd`** plays three seeds through all 14 days with time actually advancing.
  Keep it that way: a version that only *plans* each day leaves the mobile one-shots unfinished and
  the whole successor-and-scar chain untested while the test passes.
- **Not tested, checked by eye:** layout, colour, readability, whether a cue is legible from across
  a street.
- A test asserting a *relationship* beats one asserting a value. `intensity < walking decay`
  survives rebalancing; `intensity == 3.2` does not.
- **A test that is true by luck is worse than no test.** Two have been found here — a determinism
  guarantee that stayed green because one seed happened to generate a different city, and a crowd
  predicate that asserted the wrong thing for eleven milestones. If a test would pass with the code
  deleted, or passes only on the seed it was written against, it is not holding anything.
- The suite must exit clean. Leak warnings at shutdown mean a real retain bug.

---

## Things deliberately not done

Do not "fix" these without a reason; each was a decision.

- **Closures are checked before they are accepted, not repaired afterwards.** The obvious shape —
  place N closures, then drop them until the day is legal — has an order-dependent answer and a
  window where the day is illegal. Testing each candidate against the invariant before accepting it
  is the same cost and has neither problem.

  **The same rule applies to events.** Refusing the ground (`EventScheduler._calm_to_leave_alone`)
  keeps every unvisited calm area clean and *raises* the density, because a repair spends the budget
  twice. **If you find yourself writing a pass that deletes what a previous pass placed, this is the
  rule you are about to rediscover.**
- **Counting distinct routes is a max flow, not a search for routes.** By Menger's theorem, two
  edge-disjoint paths is also "no single street cuts this off". Two BFS augmentations on a 64-node
  graph, not a flood fill over ten thousand tiles — which is why it can run on every candidate
  closure, every day.
- **No spatial hash for events.** The budget tops out near 25 concurrent events. A linear scan is
  free and a hash is more code with more ways to be subtly wrong.
- **No `impulse` field on events.** A sharp spike is a short `duration` at high `intensity`, which
  keeps the excitement model a pure query.
- **Events are defined in code, not `.tres`.** Reviewable in a diff, validated on load, assertable
  as a whole catalogue in a test.
- **No quest log or marker for the resistance** — *asked for X · overturned to Y on 2026-08-31,
  because the risk was run and did not pay off.* **Half of it survives and the half is the point.**
  The **first** encounter comes with no hint at all — *"yes, no hint even at the bottom left"* —
  because finding the difficulty dial is still meant to be the player's own doing. After that the
  resistance **speaks**: the day brief carries the chalk marks' own words.
- **The home's doorstep is exempt from the route-redundancy guarantee.** The home is a notch with
  one exit, so sealing that street seals the player in. It is a constraint on where Act IV may
  barricade, not a layout flaw.

---

## Two measured facts about the catalogue

The full table is in `docs/EVENTS.md`, "What an event actually costs" — regenerate it whenever a
rate in `Tuning` moves, because it is the fastest way to see what a balance change did to the whole
catalogue.

- **Walking through an event costs, and the falloff's shoulder is why.** `dog_walker` is +36.5,
  `cafe_tables` +20.1, and one row stays negative on purpose — `burnt_shell` is a reminder rather
  than an obstacle. `tests/test_events.gd` names exactly that one as the exemption, so a **second**
  negative event has to be a decision somebody takes rather than a number nobody checked.
- **Running is the wrong move against every event you route *around*, and the right move against the
  one kind of thing that follows you.** `EXCITEMENT_FROM_RUNNING` plus the collapsed decay (3.5/s →
  0.5/s) beats the shorter exposure for every row that merely emits, and `tests/test_events.gd`
  asserts it row by row — it had only ever been *measured* and written down, and a change to the
  falloff shape broke it silently in four rows before anyone noticed. The exception is
  `EventDef.pursues`: faster than a walk, slower than a run, lethal, and it gives up. Walking and
  running give **opposite outcomes** rather than the same outcome at two prices, which is exactly
  why it had to be a mechanic rather than a constant. Nothing pursues before `Tuning.RUN_TAUGHT_DAY`
  — day 1 teaches the arrow keys and day 3 teaches the run, with the thing that requires it.

**And facts the table does not cover.** The cost of a route is not only the events on it: a contact
with a pedestrian is ~10.8 points and a car's horn ~8, and neither is in the catalogue. **A balance
argument that reaches for the cost table alone is answering a narrower question than it thinks.**

Most stationary rows are solid, so "walk straight through the centre" is a line the player cannot
take against about two thirds of the catalogue. The integral is still the right price for *being
close*, and being stopped by a body is a route cost the table has never counted.

**The careless line and the careful line, re-measured over five seeds of forty-second walks:** 73
contacts down an arterial lane centre against 5 on the midline between two lanes — 14.6:1. The
ratio, not either number, is what makes the crowd a decision.

**The careful line has to be wide enough to aim at.** A contact fires inside `BUMP_RADIUS` of a lane
centre, so with lanes a tile apart the clear line is `32 − 2 × 14` = four pixels, which is not
something a player aims at. `CrowdLanes.SIDEWALK_LANE_SPREAD` widens it by moving the two lanes of a
footway toward the pavement's own edges. **Widen the street, not the body** — `BUMP_RADIUS` is what
makes a contact mean *walking into somebody*, and buying the same line by shrinking it would make a
contact require a near-perfect overlap.

**When two systems price the same choice, check they are not pricing it in opposite directions.**
Before that change, contacts and ambient noise wanted opposite lines and a player who found one had
found the other's punishment. That is not a balance error, it is a design that cannot be played.

**Walking an ordinary pavement is free; standing on one is not.** Every line across an ordinary
footway is net recovery while walking — the crowd charges 55–87 points over forty seconds against a
decay that pays back 140. The cost of standing is `EXCITEMENT_DECAY_IDLE`, which is zero recovery,
and not the crowd.

## Known-shaky ground

What is untested by a human, listed so nobody mistakes arithmetic for a verdict.

- **The difficulty has been felt by a human once**, and that was a verdict on one density pass and
  one act I. The sleepiness numbers, the nerve economy, and whether the arterial is crossable are
  all still arithmetic checked by `tests/test_balance.gd` and unfelt. **Nobody has ever got past day
  4**, so the whole of acts II–IV is seen by nobody.
- **Five nerves is a number nobody has played against.** It was raised from three after a run ended
  on day 3 — but two of those nerves went on a **defect**, so the number was raised against a
  difficulty that no longer exists.
- **A spoiled park is nine things and nobody has stood in one.** The coverage is measured — 91% of a
  courtyard, 99% of a four-block zone — and what is not measured is whether it reads as *the park is
  busy today* or as somebody having tipped an event budget into a field. It is also the one place
  where `EVENT_SPACING_SAME` does not apply.
- **The robber and the pacing man have never been met by a person.** The robber is the most
  mechanically complicated row in the catalogue — a field, a trigger, a notice, a stand-off and a
  break-off — and every number on him is a rig's. The pacing man is a man with no body on a 64px
  footway, avoided by the meter alone.
- **A street that is solid has been walked by a rig and by nobody.** About two thirds of the
  catalogue has a body. The open question is not density but whether being stopped reads as *cross
  the street* or as an obstacle course. The gap between a kerbed van and the frontage is smaller
  than the pram, which is intended and is also the exact shape of *"no line to walk"*.
- **Most of the silhouettes have never been seen in play.** The contact sheet is the only thing that
  has looked at them and only five are reachable before day 4. The two to distrust are the ones that
  are more than a picture: the **robber's two postures**, where the whole claim is that *waiting*
  and *coming* are told apart at an alley's length, and the **protest**, a 110px wall of bodies on a
  crossing.
- **A flock has been walked through by a rig and by nobody.** The gradient is measured — +35 through
  the middle, +8 eighty pixels off it, nothing at the rim — and it is the only row where the cost
  table and the thing the player meets are computed differently.
- **The park is 20% faster and nobody has felt it.** Calm ground fills the meter in 20s rather than
  24, which narrows the "a calm area is more than one lap" margin in `docs/MECHANICS.md` to 19.8s
  against a 10.8s lap.
- **There is no audio at all.** Less urgent than it sounds, given the rule above: audio is
  redundancy, so the game must already be fully playable without it.
- **Dev flags are always on.** `--seed`, `--day`, `--spawn`, `--follow`, `--meters`, `--overview`,
  `--day-length`, `--screenshot`, `--after`, `--walk`, `--flee`, `--press` ship in the build. They
  should be gated behind a debug build before release.
- **There is no main menu.** There is a **title screen** — the doorstep with the traffic and the
  events running behind it, `space` to begin, and a finished run goes back to it — but it is a
  title, three lines of controls and two keys: no options, no seed box, no load game. `Esc` opens a
  pause screen, `R` inside it starts the run again and `Q` quits; the between-days summary is its
  own kind of pause, and the pause opens over it.
