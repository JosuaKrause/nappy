## M126 — The codebase audit · filed 2026-09-13

*(2026-09-13, [PLAYTEST-67](../playtests/PLAYTEST-67.md): "Other than that do a thorough audit of the
codebase.")* A read-only pass over `src/` (38,474 lines, 85 scripts), `tests/`, `tools/` and
`.claude/hooks/`, recorded whole in `docs/evidence/audit-2026-09-13/AUDIT.md`. 28 findings, by the
report's own summary table:

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

**Where each finding went.**

- **Fixed on this branch**: 1.1 (`--start-escape` now teleports to the named part), 5.1 (the test
  that would have caught it), 5.2 (the two orphaned `.uid` sidecars), 6.1 (`lint.sh` errors on a
  named file that does not exist), 6.2's validation half (`test.sh` rejects a non-positive
  `TEST_SHARDS` before planning), 6.3 (the hook's cli-tools case and `CLAUDE.md`'s table), 7.1,
  7.2, 7.3, 7.4 (the four doc-vs-code mismatches, and the two `*(done)*` markers plus the widened
  lint check that would have caught them), 8.1, 8.2, 8.3 (the three dead functions), 8.5, 8.6, 8.7
  and the two unnumbered stale comments beside them, and the `tuning.gd` docstring, `hud.gd`'s
  `_debug` line and `city_generator.gd`'s silent fallback named alongside them. 8.4 needed no
  separate action: `part_world_position()` gained the caller 1.1's fix gives it.
- **Not fixed, filed under M100** instead: `event_manager.gd:321`'s reach into
  `EventInstance._noticed_at` needs a getter on `EventInstance`, which was out of scope on this
  branch (owned by the concurrent M124 fixes agent); 6.2's hang-timeout half (a hung shard blocks
  `wait` forever with no message); 3.2 (`Crowd.step()` and `Crowd._physics_process()`'s duplicated
  prologue) and 4.1 (the seven hand-written spellings of "is this the main road").
- **Filed under M124**: 2.2, 2.3, 2.4, 2.5, 2.6 and 4.2, the per-frame and per-call costs the
  frame-cost measurement's own table did not itemise (the halo's per-frame allocations, the
  doubled `contribution_at` sweep, `DangerEdge`'s per-frame dictionaries, `DebugLayers`' repeated
  tree walk, the day clock's 60Hz reformat, and `ReachabilityGrid`'s recomputed dirty set). 2.1 is
  not filed again: it is M124's own first item, already being built on its own branch.
- **Asked as a question**, under M100's open design questions: 3.1, whether `CrowdAgent` should
  move from `_process` to `_physics_process` so the crowd's own right-of-way rules run at the same
  cadence as the motion they govern, against leaving the mismatch as it is.

**What was looked at and found clean**, so the next audit starts from here rather than from
scratch — verbatim from the report:

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
`./tools/pycheck.sh` (ruff, ruff format, strict mypy, 8 unit tests) and `tools/test_cli_help.sh`
all pass on the audited tree. `check.sh` correctly reverted `docs/ARCHITECTURE.md` after the
import pass rewrote it.

See `docs/evidence/audit-2026-09-13/AUDIT.md` for the full report: every finding's file, line,
failure scenario and fix size.
