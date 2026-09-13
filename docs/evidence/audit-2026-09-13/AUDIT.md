# M126 — The codebase audit

Read-only pass over `src/` (38,474 lines, 85 scripts), `tests/`, `tools/` and `.claude/hooks/`
at the repo root on `worktree-agent-a6c90f16d3a7d2d7e` (level with `5ba4d100`). No file in the
repository was changed. `./tools/check.sh`, `./tools/lint.sh`, `./tools/pycheck.sh` and
`tools/test_cli_help.sh` were run and all pass.

Numbers quoted as "live events" and "crowd" come from the `check.sh` boot line on seed
3316731638: `day 1 started ... 345 events (41 live, 28 ahead), 234 crowd`.

## Summary

| Area | defect now | defect waiting | cost | hygiene | total |
|---|---|---|---|---|---|
| Escape scene (`--start-escape`) | 1 | 0 | 0 | 0 | 1 |
| Per-frame drawing and allocation | 0 | 0 | 6 | 0 | 6 |
| Crowd and traffic | 0 | 2 | 0 | 0 | 2 |
| City and routes | 0 | 1 | 1 | 0 | 2 |
| Tests and rigs | 1 | 0 | 0 | 1 | 2 |
| Tools and hooks | 1 | 2 | 0 | 0 | 3 |
| Docs vs code | 1 | 1 | 0 | 3 | 5 |
| Dead code and stale references | 0 | 0 | 0 | 7 | 7 |
| **Total** | **4** | **6** | **7** | **11** | **28** |

---

## 1. Escape scene

### 1.1 `--start-escape <part>` never teleports anywhere — defect now

**Where.** `src/main.gd:383` (`_escape_start_part()`), `src/main.gd:265` (its only caller),
`src/main.gd:428` (`_on_finale_section_started`), `src/interior/interior_scene.gd:488`
(`part_world_position`).

**What the code does.** `_escape_start_part()` maps the flag's word onto an `InteriorMap.PARTS`
waypoint name (`"stairwell:left"` → `"stairwell_left"`, `"basement"` → `"basement"`, and so on).
It is called in exactly one place, `main.gd:265`:

```gdscript
var start_at_the_city := _escape_start_part() == "city"
```

— and the result is used only to test equality with `"city"`. When section one begins,
`main.gd:428` puts the player at `_interior.start_world_position()`, which is unconditionally
`_plan.start_tile`, her own third-floor door. `InteriorScene.part_world_position(part)`, the
function that would resolve the mapped word to a position, has **no caller anywhere in `src/` or
`tests/`** — the only references in the tree are in an archived capture script under
`docs/evidence/archive/session-captures/2026-09-12/`.

**What is wrong.** Six of the seven documented values of `--start-escape` do nothing. Only
`city` changes the boot.

**Failure scenario.** An agent asked to photograph the basement runs
`tools/shot.sh out.png 6 --start-escape basement`, gets a picture of the third-floor hallway, and
reports on the basement's lighting. The same holds for every graphics review of a stairwell or
the lobby, and for any attempt to reproduce a playtest report about one of those parts.

**Four places assert the feature works.** `docs/ARCHITECTURE.md:180-186`: *"`--start-escape` takes
an optional value — `stairwell:left`, `stairwell:right`, `lobby`, `basement` or `floor:2`/`floor:1`
— that teleports straight to that part of the escape scene's one building-wide map instead of
starting at her own door on the third floor."* `main.gd:218-220`: *"`DevFlags.start_escape_at()`'s
optional value teleports straight to any of the building's other six parts."* `main.gd:372-374`:
*"mapped onto the `InteriorMap.PARTS` waypoint to teleport to before the first frame."*
`interior_scene.gd:485`: *"what `--start-escape <part>` teleports to."*

**Fix.** In `_on_finale_section_started()`, use `_interior.part_world_position(_escape_start_part())`
instead of `_interior.start_world_position()` on the first (non-restarted) `BUILDING` entry —
`part_world_position` already falls back to `start_world_position()` for an unrecognised word, so
the default boot is unchanged. Add a test that the mapped word reaches a position (see 5.1).

**Size.** Two lines plus a test. **Severity.** Defect now.

---

## 2. Per-frame drawing and allocation

This section is the static reading the frame-instrumentation agent can compare against. The
short version: **42 unconditional `_draw()` calls per frame (41 live event instances + the
stroller), up to 96 additional body re-draws from the halo rings, and the crowd's own
change-gated redraws on top.** The largest single avoidable item is 2.1.

### 2.1 `EventInstance` asks for a redraw every frame; `CrowdAgent` does not — cost

**Where.** `src/events/event_instance.gd:1017`, `:1040`, `:1079` — every exit from `_process()`
calls `queue_redraw()` unconditionally. Compare `src/crowd/crowd_agent.gd:814-825`,
`_redraw_if_the_picture_changed()`, whose own comment reads: *"Moving a Node2D does not invalidate
its draw list — the transform is applied when it is replayed — so an agent only redraws when its
picture actually changes. At this population that is the difference between five hundred redraws
a frame and a handful."*

**What is wrong.** The reasoning that earned the crowd its gate applies unchanged to events, and
events never got it. Most of the ~41 live instances on a day are stationary scenery whose picture
is byte-identical frame to frame: seals (`barricade`, `fallen_tree`, `car_accident`,
`burst_water_main`, `collapsed_frontage`, `burnt_out_car`), the region wall's and doors' bodies
(`checkpoint_hut`, `checkpoint_gate`, `checkpoint_post`), `cafe_tables`, `construction`,
`market_stall`, `poster_crew`, `burnt_shell`.

**Failure scenario / cost.** Each redraw re-runs the row's whole `_draw_body` — `_draw_protest`
lays out two ranks of placards and asks `_protest_objective()`; `_draw_cafe` lays out tables and
sitters; `_draw_spread` walks a run of segments. All of it is thrown away and rebuilt 60+ times a
second for pictures that did not move. This is the item most likely to dominate the sibling
agent's `_draw` profile.

**Fix.** Give `EventInstance` the same gate: a `Vector3i`-style picture key over
(`_gait_stepping()`, view sector / mirror, `_caret_strength()`, quantised `_current_bob()`,
`is_leaving`), and `queue_redraw()` only when it changes. Anything animated already changes one of
those. **Size.** A function. **Severity.** Cost.

### 2.2 `ExcitementHalo._process()` rebuilds a ~275-element array and does a linear `in` per candidate — cost

**Where.** `src/ui/excitement_halo.gd:215-232`.

**What the code does.** Every frame it allocates a fresh untyped `Array`, `append_array`s
`_events.instances()` (41) and `_crowd.agents()` (234) into it, calls `select_sources()` — which
allocates one two-element `Array` per candidate above the floor and runs `sort_custom` with a
freshly-constructed lambda — then loops all 275 candidates doing `if source in picked:`
(`:227`), a linear scan of an array of up to `MAX_SOURCES` (8).

**What is wrong.** Three avoidable per-frame costs in one function: a 275-element array
allocation, N small array allocations for the ranking, and an O(275 × 8) membership test where a
`Dictionary` keyed on `get_instance_id()` is O(275).

**Failure scenario / cost.** ~2,200 `Variant` comparisons and ~280 heap allocations per frame,
every frame, for the whole of every day — in a class whose own doc says the cost is *"bounded by
the selection rather than by the crowd"*, which is true of the drawing and false of the selection.

**Fix.** Keep one reusable member array for `candidates`; have `select_sources()` return a
`Dictionary` of picked instance ids (or set a flag on each picked source before the loop) and test
that instead of `in`. **Size.** A function. **Severity.** Cost.

### 2.3 The same `contribution_at(player)` sweep runs twice per frame from two owners — cost

**Where.** `src/player/baby.gd:108` (`_world.excitement_sources_at(here)` at physics rate) and
`src/ui/excitement_halo.gd:221-222` (`source.contribution_at(at)` inside `select_sources`, at frame
rate). Both ask every live event and every crowd agent for its contribution at the **same**
point — `Stroller.global_position` in one and `_player.global_position` in the other.

**What is wrong.** `contribution_at()` is not free: `CrowdAgent.contribution_at`
(`src/crowd/crowd_agent.gd:838`) does a `GroundShape.eccentric_distance()` plus one or two
`Tuning.falloff()` calls. It is computed ~275 times for the meter and ~275 times again for the
halo selection, for the same query point, in the same tick.

**Failure scenario / cost.** Roughly 550 falloff evaluations per frame where 275 would do, plus
`City.excitement_sources_at` (`src/city/city.gd:254`) allocating one outer array and one
two-element array per contributing source on the meter side as well.

**Fix.** Cache `contribution_at(player_at)` on each source, keyed on the frame — the same
once-a-frame shape `EventInstance._caret_strength()` (`event_instance.gd:2223`) already uses and
documents. The halo already tells every candidate `set_player_at(here)`, so the key is to hand.
**Size.** A function. **Severity.** Cost.

### 2.4 `DangerEdge._measure()` allocates one `Dictionary` per live instance per frame — cost

**Where.** `src/ui/danger_edge.gd:107-150`. `next[id] = {"was": at, "approach": approach,
"hold": hold}` at `:138`, inside a loop over every live instance; `_watch = next` at `:149`; a
`sort_custom` with a freshly-constructed lambda at `:150`. The class doc at `:85-87` states the
design: *"Keyed by instance id and rebuilt every frame."*

**What is wrong.** ~41 `Dictionary` allocations plus one outer `Dictionary` plus up to 41
four-element `Array`s in `_coming`, every frame, to carry three floats per instance.

**Fix.** Mutate the existing per-instance dictionaries in place and delete only the ids that went
away, or keep the three fields on the `EventInstance` itself the way `plan.age`/`plan.travelled`
already carry stream state. **Size.** A function. **Severity.** Cost.

### 2.5 `DebugLayers` walks the whole city tree, three times, every frame — cost

**Where.** `src/dev/debug_layers.gd:90-91` (`_process` calls `queue_redraw()` unconditionally,
even with all three layers off), `:200-203` (`_draw_bodies`), `:230-244`
(`collision_nodes_under`), `:211-213` (`body_outline_count`).

**What the code does.** `collision_nodes_under(root)` is a recursive walk that allocates a new
`Array[Node]` at **every** recursion level (`found.append_array(collision_nodes_under(child))`).
`_draw_bodies()` calls it on `_city` — every building, prop, event instance and crowd agent and
all their children — and again on `_player`, once per frame while layer 3 is on.
`body_outline_count()` calls it twice more.

**Failure scenario.** Pressing `3` in a debug run — the documented way to check a body by eye
(`docs/ARCHITECTURE.md:200-210`) — costs thousands of node visits and hundreds of array
allocations per frame. The frame rate drops, so the car turn or walker sidestep being inspected
is no longer running at the speed a player sees, and the picture being judged is not the picture
under judgement. This is the layer most likely to be on when the frame is being measured.

**Fix.** Two independent changes: gate `_process`'s `queue_redraw()` on
`fields_on or shadows_on or bodies_on`; and build the node list into one passed-in array
(`collision_nodes_under(root, into)`) cached per day or rebuilt on `child_entered_tree`, rather
than reallocating per level per frame. **Size.** A function. **Severity.** Cost.

### 2.6 The day clock is re-formatted 60 times a second for a string that changes once a second — cost

**Where.** `src/day/day_controller.gd:61` emits `EventBus.day_time_changed` unconditionally every
`_process` frame; `src/ui/hud.gd:312-320` handles it with a `%` format (or
`GameState.format_clock()` in the finale, which allocates and does three more `%` substitutions)
and a `Color(...)` construction and `modulate` assignment on every one.

**What is wrong.** The displayed string changes once per second; the work is done every frame.
`Label.text`'s own equality check saves the relayout but not the formatting or the allocation.

**Fix.** Emit only when `int(time_remaining)` changes, or compare in the handler before
formatting. **Size.** A sentence. **Severity.** Cost.

---

## 3. Crowd and traffic

### 3.1 `CrowdAgent` moves at frame rate; every rule about that movement is applied at physics rate — defect waiting

**Where.** `src/crowd/crowd_agent.gd:701` is `_process(delta)` — frame rate. Everything that
governs it is in `src/crowd/crowd.gd:625`, `_physics_process(delta)` — fixed 60 Hz:
`space_out_the_traffic()`, `_hold_walkers_at_doors()`, `give_way_at_junctions()`, `_strike()`,
`_horn()`, `_bump()`, `_make_way()`.

**What is wrong.** Speeds are frame-rate independent (each integrates `delta`), so this is not a
speed bug. What varies with the machine is the **decision cadence relative to the motion**: how
far a car travels between two applications of *"nothing enters a box it cannot leave"*. The
verify skill records that the windowed build draws ~110fps, so on a desktop a car covers roughly
1.8 movement steps per right-of-way pass; at 30fps it covers 0.5. The crowd-traffic skill's own
*"An approach arrives late, so the guarantee is positional"* is exactly this class of problem,
and `_keep_out_of_a_body()` is the positional guard built for it — but the box-holding and
right-of-way rules are not positional in the same sense.

**Failure scenario.** A headway or junction-capacity number set against `Crowd.step()` (see 3.2,
where the ratio is exactly 1:1) does not reproduce on the 110fps machine the player is on. The
balance skill's *"measure the mean speed and the stopped fraction alongside the floor"* is
measured at a ratio the game never runs at.

**Fix.** This is a decision, not a one-liner: moving `CrowdAgent._process` to `_physics_process`
fixes the ratio at 1:1 everywhere, at the cost of re-measuring every crowd number and giving up
frame-rate-smooth motion for the agents. **Size.** A milestone, and it should go back to the
player as a question rather than be taken as a fix. **Severity.** Defect waiting.

### 3.2 `Crowd.step()` and `Crowd._physics_process()` duplicate four lines in two orders — defect waiting

**Where.** `src/crowd/crowd.gd:230-237` (`step`) and `:625-638` (`_physics_process`).

```
_physics_process: _signals.advance → _pockets.refresh → space_out_the_traffic → _hold_walkers_at_doors → [player half]
step:             _signals.advance → _pockets.refresh → agent._process (all) → space_out_the_traffic → _hold_walkers_at_doors
```

**What is wrong.** The shared prologue exists twice with no shared helper. The crowd-traffic skill
names the incident this already caused once — *"a rig that walked the agents without it would run
a crowd in which nobody is ever held at a checkpoint, and nothing about that looks like a missing
call"* — and `step()`'s own doc repeats it. The structure that allowed it is unchanged, so the
next line added to `_physics_process`'s pre-player section is silently absent from every
rig-driven suite.

**Failure scenario.** Somebody adds a per-frame pass to `_physics_process` (a new shared index,
a second pocket refresh) and every crowd suite stays green while the rig runs a crowd the engine
never runs.

**Fix.** Extract the four shared lines into `_advance_the_world(delta)` and have both call it, so
the only difference between them is the agent stepping and the player half. **Size.** A function.
**Severity.** Defect waiting.

---

## 4. City and routes

### 4.1 Seven hand-written spellings of "is this the main road" — defect waiting

**Where.** `src/city/traffic_signals.gd:52` (`junction.x == _map.main_road`),
`src/crowd/crowd_lanes.gd:164` (`vertical and index == map.main_road`),
`src/crowd/crowd_agent.gd:461`, `:1560`, `:2387`, `:2404`
(`kind == Kind.CAR and _vertical and _corridor == _map.main_road`),
`src/routes/seal_planner.gd:373-374` (`not segment.horizontal and segment.a.x == map.main_road`),
plus `src/city/city_generator.gd:170`, `:526-535`. Separately,
`src/city/city.gd:244` asks the same question through a different mechanism entirely:
`map.street_kind_at(...) == GameEnums.StreetKind.MAIN`.

**What is wrong.** The city skill states the exact trap — *"Five places have to agree and the
failure mode of each is silent"*, and *"Which corridor is the main road is a fact about a city, so
read it off the map"*. Every site does read it off the map, so today they agree; what is missing
is one predicate. Each site independently re-encodes the assumption that the spine is the
**vertical** corridor.

**Failure scenario.** If `main_road` ever becomes a per-axis pair, or the spine becomes
horizontal on some seeds, six of the seven sites keep answering for the vertical axis with no
error anywhere — which is the "phantom arterial on the other axis" the generator's own docstring
at `city_generator.gd:133-136` warns about, arriving from the other direction.

**Fix.** `CityMap.is_main_road(vertical: bool, corridor: int) -> bool`, and route every site
through it. **Size.** A function plus the call sites. **Severity.** Defect waiting.

### 4.2 `ReachabilityGrid.reaches()` recomputes the dirty-cell set on every call — cost

**Where.** `src/routes/reachability_grid.gd:252-255`. `reaches()` calls `_dirty_cells(blocked)`
(`:188-192`), which allocates a `Dictionary` keyed by `Vector2i` and fills it with one entry per
blocked tile — on **every** call. Callers loop it:
`src/routes/closure_planner.gd:226-228` (`_area_is_reached`, once per tile of a calm area's rect),
`src/city/city_map.gd:576-579` (once per tile of every closed street),
`src/events/event_scheduler.gd:1467-1469`.

**What is wrong.** A `Dictionary` keyed by `Vector2i` hashes a `Variant` on every insert — the
exact cost the city skill warns about — and the set is identical for every call in the loop,
since the caller passes the same `blocked` it passed to `flood()`.

**Failure scenario / cost.** `ClosurePlanner._invariant_holds()` runs once per candidate closure,
and each run calls `_area_is_reached` once per calm area. A calm area's rect is up to 22×22 tiles
and a candidate's barrier set is ~24 tiles, so a single unreached area costs ~11,600
`Vector2i`-keyed inserts, all of them rebuilding the same answer. Day planning is already the
~1000ms wait the `_start_day()` timing print exists to watch.

**Fix.** Have `flood()` return the dirty set alongside `reached` (or accept a precomputed one),
and have `reaches()` take it rather than recompute it. `_cell_of_tile` at `:186` can also drop its
`floori(float(x) / CELL)` for integer arithmetic, and `_neighbours_of_key` at `:213` allocates the
four-offset array literal on every call — the city skill's *"write the four neighbour steps out"*.
**Size.** A function. **Severity.** Cost.

---

## 5. Tests and rigs

### 5.1 `tests/test_finale.gd` pins the string table and not the thing the table is for — defect now (with 1.1)

**Where.** `tests/test_finale.gd:342-346`.

```gdscript
t.check(MAIN_SCRIPT.escape_part_for("city") == "city", ...)
t.check(MAIN_SCRIPT.escape_part_for("") == "hallway_third", ...)
t.check(MAIN_SCRIPT.escape_part_for("nonsense") == "hallway_third", ...)
```

**What is wrong.** Three of seven rows are checked, and all three check the *mapping* rather than
the *teleport*. No test asks whether the mapped name reaches a position, which is why 1.1 has been
shipped and released with four docstrings describing it. This is the verify skill's *"a test that
reads a design decision back to itself"* on one axis and *"a guarantee with no test"* on the
other: the string table is restated, and the wiring the table exists for is untested.

**Fix.** Alongside the 1.1 fix, assert that
`InteriorScene.part_world_position(Main.escape_part_for("basement"))` differs from
`start_world_position()` and lands on a walkable tile, for each of the six part words.
**Size.** A function. **Severity.** Defect now (the code half); the test is what would have caught it.

### 5.2 Two orphaned `.uid` sidecars — hygiene

**Where.** `tests/test_limb_attachments.gd.uid` and `tests/test_mother_attachments.gd.uid` — no
matching `.gd` exists. No other orphan in `src/`, `assets/` or `scenes/`.

**What is wrong.** A `.uid` for a script that was deleted. Harmless today; it is noise in
`git status` after an import pass and a false positive for anybody grepping the suite list.
**Fix.** Delete them. **Size.** A sentence. **Severity.** Hygiene.

### 5.3 The runner's own notes on hangs are accurate; the shard reporter's are not

Covered under 6.2 — `tools/test.sh`'s "it crashed or hung" branch cannot be reached on a hang.

**Clean here:** every suite under `tests/` and `tests/probes/` extends `RefCounted` (65 of 65), so
the runner's `(load(path) as GDScript).new()` at `run_tests.gd:27` leaks nothing. `_discover`
(`:58-76`) correctly records a failure for a filter that matches nothing, and correctly refuses to
walk `tests/probes/` except by explicit path. `tools/test.sh`'s shard plan is built from disk
rather than from a list, which is the one thing it says it must do.

---

## 6. Tools and hooks

### 6.1 `tools/lint.sh` accepts a path that does not exist and reports `OK` — defect now

**Where.** `tools/lint.sh:139` (`[[ -f "$f" ]] || continue`), against its own usage text at
`:31-40` and the cli-tools rule *"An unknown flag, a flag missing its value, or **a stray word** is
rejected"*.

**Measured:**

```
$ ./tools/lint.sh docs/NOSUCHFILE.md
OK
exit=0
```

An unknown *option* is correctly rejected (`--bogus` → usage on stderr, exit 2). An unknown
*file* is silently skipped and the script prints its success line.

**Failure scenario.** The `PostToolUse` hook (`.claude/hooks/lint-docs.sh`) passes the edited
path. If that path is ever wrong — a rename in the same turn, a worktree-relative path, a typo in
a manual invocation — the lint passes green having checked nothing, and a stale sentence goes into
the commit. That is the precise failure the file's own header says it exists to prevent: *"fails
loudly instead of waiting for the next reader to notice a lie."*

**Fix.** Error and exit non-zero on a named file that does not exist. **Size.** A sentence.
**Severity.** Defect now.

### 6.2 `TEST_SHARDS` is unvalidated; `--plan` under a bad value exits 0 having printed nothing — defect waiting

**Where.** `tools/test.sh:27` (`SHARDS="${TEST_SHARDS:-4}"`), `:174-180` (the `--plan` loop),
`:196-205` (the launch and `wait` loops).

**Measured:**

```
$ TEST_SHARDS=0 ./tools/test.sh --plan     # prints nothing, exit 0
$ TEST_SHARDS=-1 ./tools/test.sh --plan    # prints nothing, exit 0
$ GODOT=<stub> TEST_SHARDS=0 ./tools/test.sh
./tools/test.sh: line 205: pids[@]: unbound variable
exit=1
```

**What is wrong.** The value is used as a loop bound in four places and is never checked to be a
positive integer. A real run under it dies on a bash array expansion rather than on a message, and
`--plan` — the flag whose entire reason for existing is that *"the failure this file has already
had once was a planning bug that looked exactly like a working run"* — reports a working run that
would run nothing.

**Fix.** Validate `SHARDS` is an integer ≥ 1 before `_plan_the_shards`, with the usage and a
non-zero exit otherwise. **Size.** A sentence. **Severity.** Defect waiting.

Related and smaller: `tools/test.sh:212-230`'s "A shard that printed no count did not finish...
it crashed **or hung**" branch sits after `wait`, so it can only ever be reached for a crash. A
hung shard blocks `wait` forever and CI waits out its own job timeout with no message. The
comment claims a case the code cannot reach. A `timeout` around `run_one_process` would make the
comment true.

### 6.3 The hook's path map and `CLAUDE.md`'s table disagree, and one entry point is missing — defect waiting

**Where.** `.claude/hooks/project-rules.sh:55-115` against `CLAUDE.md`'s "The rules load
themselves" table.

**Two problems.**

**(a) Four hook rules the documented table does not name.** The hook maps
`*/assets/illustrated/*|*/src/visuals/*` → `illustrated-png`,
`*/docs/evidence/archive/rejected-graphics/*` → `rejected-graphics`,
`*/docs/evidence/archive/session-captures/*` → `session-captures`, and `*/docs/reference/*` →
`reference-photos`. None appears in `CLAUDE.md`'s table. A reader consulting the table to learn
what governs `src/visuals/` concludes "`godot` only" and misses `illustrated-png` — and
`CLAUDE.md` itself frames the table as the documentation of the hook ("If a new area of the tree
needs rules, add the path to the hook script as well, or the rule is only a suggestion").

**(b) `src/dev/auto_screenshot.gd` gets no `cli-tools` rule.** The hook's cli-tools case is
`*/tools/*|*/src/dev/dev_flags.gd`. But `docs/ARCHITECTURE.md:187-189` records that
`src/dev/auto_screenshot.gd` *"parses `--screenshot` and the flags nested under it (`--after`,
`--walk`, `--flee`, `--press`, `--tap`) **itself**, and gates its own entry point the same way
rather than moving that parsing out."* It is a second command-line entry point in `src/dev/` and
the rule that governs entry points does not fire on it.

**Failure scenario.** Somebody extends `--walk`'s step grammar in `auto_screenshot.gd` without the
cli-tools rule in context, and a malformed step is skipped rather than failing the whole script —
which is the exact behaviour the verify skill records as already having been decided against.

**Fix.** Add `*/src/dev/auto_screenshot.gd` to the cli-tools case; bring the four missing rows
into `CLAUDE.md`'s table. **Size.** A sentence each. **Severity.** Defect waiting.

**Clean here:** `project-rules.sh`'s repo-root containment check (`:47-52`) correctly stops a
same-named directory elsewhere on disk from receiving these rules; the `set -u` + empty-array
hazard on macOS bash 3.2 (`for skill in "${wanted[@]}"`) is guarded by the `[ ${#wanted[@]} -eq 0 ]
&& exit 0` immediately above it — verified against `/bin/bash 3.2.57`, where the guarded form is
safe and the unguarded form is not. `tools/pycheck.sh`, `tools/test_cli_help.sh` and
`tools/test_cli_help.py` all pass, and the README flag section agrees with the game's own table
across all 23 flags.

---

## 7. Docs vs code

### 7.1 `docs/ARCHITECTURE.md`'s `EventBus` block is wrong in three ways — defect waiting

**Where.** `docs/ARCHITECTURE.md:303-312` against `src/autoload/event_bus.gd`.

The doc says:

```gdscript
signal baby_state_changed(state: Baby.State)
signal event_telegraphed(instance: EventInstance)
signal event_activated(instance: EventInstance)
```

- **`Baby.State` does not exist.** The real signature is
  `signal baby_state_changed(state: GameEnums.BabyState)` (`event_bus.gd:11`). `Baby`'s only enum
  is `Cue`. Anybody copying the annotation gets a parse error.
- **The two event signals are deliberately untyped in the code**, with the reason beside them
  (`event_bus.gd:22-25`): *"`instance` is an `EventInstance`, left untyped: this autoload is
  loaded before the class is."* The doc shows the typed form the code cannot use — which is
  precisely the change somebody would "fix" it back to.
- **Eleven signals are missing** from the list: `day_time_changed`, `return_phase_started`,
  `nerves_changed`, `run_ended`, `city_wide_changed`, `crowd_bumped`, `car_near_miss`,
  `resistance_step_completed`, `resistance_step_failed`, `resistance_contact_available`,
  `city_went_quiet`.

**Fix.** Replace the block with the real one, or drop the code listing and point at the file.
**Size.** A sentence. **Severity.** Defect waiting (the `Baby.State` line).

### 7.2 `docs/ARCHITECTURE.md` carries two `*(done)*` markers and the linter cannot see them — hygiene ×2

**Where.** `docs/ARCHITECTURE.md:418` and `:420`, both ending *"...against a fake world.
*(done)*"*. `CLAUDE.md`: *"A ticked box, a 'Done:' paragraph, a branch name or a status word in a
heading is a quest log **wherever it stands**."*

**Why the gate missed it.** `tools/lint.sh:119-132` (`lint_heading_status`) only inspects lines
matching `^#{1,4} .*·` — a heading containing a middot. A `*(done)*` at the end of a bullet is
outside its reach, and `lint_ticked` only matches `- [x]`. `./tools/lint.sh` exits 0 on the
current tree.

**Fix.** Two: delete the markers; and widen `lint.sh` to report `(done)`, `Done:` and the other
status words anywhere in a governed doc, not only after a middot in a heading. **Size.** A
sentence and a function. **Severity.** Hygiene ×2.

### 7.3 `docs/MECHANICS.md` still names a warning ring — hygiene

**Where.** `docs/MECHANICS.md:881`: *"The event is **visible** (sprite, warning ring, audio cue)."*

**What is wrong.** The cues skill's standing decision is *"No circles around entities. Do not add
a ring, and do not reach for one when something new needs signalling"*, and nothing in
`EventInstance` draws one. A governed doc names a cue the vocabulary bans.

**Failure scenario.** Somebody reading MECHANICS.md for the telegraph contract takes "warning
ring" as a description of what a telegraph draws and reintroduces the exact thing the vocabulary
was built to replace.

**Fix.** Delete "warning ring". **Size.** A sentence. **Severity.** Hygiene.

### 7.4 `docs/ARCHITECTURE.md`'s excitement sample does not match the code — hygiene

**Where.** `docs/ARCHITECTURE.md:349-356` shows `EventManager.total_excitement_at` looping over
`_active`. The real function (`src/events/event_manager.gd:534-538`) sums over
`excitement_sources_at()` pairs, and the member is `_instances`. The tree listing at
`ARCHITECTURE.md:34` also attributes `is_calm`/`is_alley` to `city_map.gd`; both live on `City`
(`src/city/city.gd:174`, `:248`).

**Fix.** Update both. **Size.** A sentence. **Severity.** Hygiene.

**Spot-checks that came back clean.** Every constant the docs name and value they quote matches
`tuning.gd`: `EXCITEMENT_DECAY_WALKING` 6.0, `_RUNNING` 0.5, `_IDLE` 0.0, calm ×2.0, precinct
×1.5, alley ×0.58, main road ×0.35, `WALK_SPEED` 92, `RUN_SPEED` 168, `EXCITEMENT_CALM_THRESHOLD`
35, `EXCITEMENT_WAKE_THRESHOLD` 60, `WAKE_SLEEPINESS_PENALTY` 50, `SLEEPING_SENSITIVITY` 0.55,
`EXCITEMENT_FROM_RUNNING` 14, `TELEGRAPH_INTENSITY_FRACTION` 0.15, `DAY_LENGTH_SECONDS` 180,
`RUN_TAUGHT_DAY` 3, `EVENT_STREAM_RADIUS` 900, `VIEW_HALF_EXTENT` (320,180),
`OBSTRUCTION_A_PARK_CAN_HOLD` 16, `MIN_CALM_AREAS_REACHABLE` 2, `PLAYER_BODY_RADIUS` 14,
`SHOTS_PER_DAY` 6, `SHOT_SPACING` 3.0. MECHANICS.md's sleepiness table arithmetic checks out
against `Tuning.sleepiness_calm_multiplier()`: 0.42×21 = 8.8 (four blocks), ×29.7 = 12.5 (two),
×42 = 17.6 (one).

---

## 8. Dead code and stale references

All hygiene, all one-line fixes. Found by cross-referencing every `func` name in `src/` against
every occurrence in `src/`, `tests/` and `scenes/`.

| # | Where | What |
|---|---|---|
| 8.1 | `src/city/block_plan.gd:73` | `static func is_built(purpose)` — no caller anywhere. Dead. |
| 8.2 | `src/crowd/crowd_lanes.gd:193` | `static func pick_corridor(...)` — no caller. `pick_corridor_in_range` (`:210`) is the one in use. Dead. |
| 8.3 | `src/routes/closure_marker.gd:39` | `static func texture_for(...)` — no caller. Dead. |
| 8.4 | `src/interior/interior_scene.gd:488` | `part_world_position()` — no caller in `src/` or `tests/`. **Not** dead code to delete: it is the missing half of finding 1.1 and should gain a caller, not lose its body. |
| 8.5 | `src/city/city_decals.gd:8` | *"`City._place_litter()` rebuilds `_placed` once a day"* — `City` has no such function; `src/city/litter.gd` is where litter lives. |
| 8.6 | `src/crowd/crowd.gd:503` | *"see `CrowdAgent._advance_the_door_hold()`"* — the real name is `advance_the_door_hold()` (public, `crowd_agent.gd:553`). |
| 8.7 | `src/player/stroller.gd:453` and `src/events/event_manager.gd:47` | *"See `EventManager._release_from_door()`, **the only caller**"* — no such function. The real ones are `_release_finished_door_detentions()` (`event_manager.gd:933`) and `_update_door_release_latches()` (`:982`). |

Two smaller ones in the same family:

- `src/autoload/tuning.gd:6-11` — the docstring says *"**the one contract** that is not about an
  event is checked here on boot"*, and `_ready()` calls three (`validate_traffic`,
  `validate_signals`, `validate_return_patrols`).
- `src/events/event_manager.gd:321` reaches into another class's private member:
  `plan.noticed_at = plan.live._noticed_at`. `EventInstance.resume(age, travelled, noticed_at)`
  is the public channel in the other direction; there is no getter for this one.
- `src/main.gd:1153-1181` — `_snapshot_now()` and `_start_burst()` are the same fourteen lines
  twice, differing only in the final call and one noun. One helper returning the context string
  would do.
- `src/ui/hud.gd:32` — `var _debug := OS.is_debug_build()`, where `main.gd:22` and every other
  gate reads `DevFlags.enabled()`. Same value today; two ways to ask one question, and the godot
  skill's rule is that the platform answers the flag rather than being it.
- `src/city/city_generator.gd:155-176` — `_place_precincts`'s inland loop (`for _attempt in 24`)
  returns on its first success and falls through silently if all 24 attempts conflict with the
  spine, leaving a city with one precinct where the docstring promises two. The probability is
  vanishing (~1e-20 on the current geometry), but the fallback is silent: no `push_warning`, and
  nothing asserts the precinct count. A one-line `push_error` on fall-through would make it
  visible if the geometry ever changes.

---

## What was looked at and found clean

So the next audit can start from here rather than from scratch.

**Leaks and retention — clean.** No `disconnect()` exists anywhere in `src/`, and none is needed:
every connection is to an autoload signal (`EventBus`, `Telemetry`) from a node the engine frees,
and Godot drops the connection with the object. `EventManager.clear()`
(`src/events/event_manager.gd:231-245`) frees every instance, nulls every `plan.live`, clears
`_door_entry_side`, `_door_release_latches` and `_sighted`, and calls
`_map.clear_day_obstructions()` — so nothing is keyed on a `Planned` across days.
`_retire_finished()` (`:764-784`) assigns in place rather than reassigning, with the reason stated,
so `instances()`' handed-out reference stays valid. `WalkerDoorHold.release()` is reached from all
four exits the crowd-traffic skill names, and `empty()` is called from `Crowd.clear()`
(`crowd.gd:183`). `Crowd.start_day()` resets `_struck` and rebuilds `_door_holds`. The static
caches — `StreetNetwork._segments`/`_by_key`/`_adjacency`, `SealPlanner._candidates` and
`_finale_candidates`, `ReachabilityGrid._mask_components`, `EventCatalogue._all`/`_hot`,
`ResistanceSteps._all`, `CityMap._WALKABLE`/`_CALM`, `EntityHalo._shared_material` — are all
bounded by geometry or by the catalogue and none grows per day or per run.
`TextureResolver._cache` is keyed on asset path and so bounded by the asset count.
`City._sleepiness_tile`'s cache is invalidated at `city.gd:467` and `:494`.

**Godot trap list — clean.** No `set(key, value)` object construction anywhere. No untyped
`Array` passed into an `Array[T]` parameter. No `var x := load(...)` inferred from a Variant —
`check.sh` boots green, which is what that would fail. The one cross-script enum widening
(`StreetNetwork.beside_block`, `street_network.gd:104`) carries its comment.
`Node.name` is shadowed by a local in three places (`main.gd:807`, `telemetry_observer.gd:268`,
`crowd_agent.gd:2886`/`event_instance.gd:2302` shadow `Node2D.scale`) — warnings, not errors, and
not worth a diff. `move_and_slide()` owns `velocity` and the shove goes through
`move_and_collide()` (`stroller.gd:304-311`) with the reason written down. Pause inheritance is
handled by `main._pauses_with_the_game()` at every construction site, with the title screen's
inverted split at `main.gd:546-555`. The three `int/int` divisions
(`region_planner.gd:693`, `interior_events.gd:127`, `finale_planner.gd:86`) are all deliberate
index arithmetic. Exactly one `assert()` in `src/` and no `TODO`/`FIXME`/`HACK` markers.

**Determinism and telemetry — clean.** `GameState.day_rng(day, stream)` is used with a named
stream at every call site; nothing in `src/telemetry/` or `Telemetry.note()` draws from an RNG,
and `TelemetryObserver` holds all the per-frame checks rather than the gameplay classes — the
telemetry skill's rule, held. `TelemetryObserver._meters()` (`telemetry_observer.gd:928`) does two
full excitement sweeps, but it is called only on bumps, near-misses and day ends, not per frame.

**Day and run state — clean.** `GameState.start_run()` resets all thirteen run-scoped members.
`finish_day()` erases `settled_in[day]` on a loss with the reasoning stated.
`resistance_carrying_package` is reset per attempt in `ResistanceDirector.start_day()`
(`resistance_director.gd:88`). `DayController._ignores_loss()` is the single place all three
losing paths ask about `--invincible`, so the flag cannot drift between them.

**Boot validation — clean.** `Tuning._ready()` runs `validate_traffic()`, `validate_signals()` and
`validate_return_patrols()`, each of which `push_error`s with the numbers. `EventDef.validate()`
runs `validate_event()` and `validate_pursuit()` per row on catalogue load.

**Gates and checks — clean.** `./tools/check.sh` (imports + headless boot), `./tools/lint.sh`,
`./tools/pycheck.sh` (ruff, ruff format, strict mypy, 8 unit tests) and
`tools/test_cli_help.sh` (53 checks) all pass on this tree. `check.sh` correctly reverted
`docs/ARCHITECTURE.md` after the import pass rewrote it.
