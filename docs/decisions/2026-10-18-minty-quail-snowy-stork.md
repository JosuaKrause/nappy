# minty-quail — The run's state is a RefCounted in src/run/, and a held restart hands the sitting a fresh one (the run's state handed in: the last three) · 2026-11-06


minty-quail's `run-state-handed-in.md`, its last three changes, which close the item: `RunState`
as a `RefCounted`, a held restart handing the sitting a new run, and the file renamed and moved
out of `src/autoload/`.

**Built.**
- `RunState` extends `RefCounted`. Nothing in it used a node: no tree access, no processing, no
  children; its signals go out through `EventBus`. `Sitting.take_the_run()` makes a run and keeps
  it by reference, with no `add_child()` and no `RUN_NODE_NAME`. Every suite's, rig's and probe's
  free of a run went (221 lines under `tests/`), with the `add_child()`s that held a run
  under a screen, a city, a world or a counter so that node's free took it, and the lists kept only
  to free runs: `tests/interior_rig.gd`'s `free_all()` and its callers, `test_run_state.gd`'s
  `_runs`, `resistance_rig.gd`'s `_own_run`, and the run fields of two rigs in `test_frame_record.gd`
  and `test_save_wiring.gd`. `test_main.gd`'s check that the run is the sitting's child keeps its
  other two clauses. The runner counted no run nodes, so nothing there changed; the shared-state
  check now follows a run an autoload holds one level down, as it does any `RefCounted`, and the
  observers a booted suite gives back cover the visit counter's run as before.
- A held restart hands the sitting a new run: `main._restart_run()` sets `Sitting.run` to a fresh
  `RunState`, which the boot after the reload starts as a first boot does (nothing to resume, no
  escape section, not carried, so `start_run()`). The old run's `escape_section` is no longer
  cleared by hand, since nothing of it reaches the next boot. What record fluffy-lark put on the
  sitting (the controls word, the restart stamp, the save symbol's home, `carry_the_run_over`)
  outlives the restart as before, and the day-14 hand-over and a carried run keep the run. The
  calendar (record minty-quail-41) is built over the new run's parts. The boot being left plays on
  its own `_run` until the reload frees it, so a check in that boot reads the old run as before.
  The escape's held-restart test reads the sitting's run (a fresh one after each of its two
  restarts, with no escape section) instead of the thrown-away run, and the atlas suite's
  restart-then-hand-over walk reads the run the reloaded boot plays off the seat's sitting.
- `src/autoload/game_state.gd` is `src/run/run_state.gd` (class `RunState`), its `.uid` with it,
  beside the parts in the model's folder. `tools/layer_map.py` loses the file entry that placed it
  on the model's layer from the observers' folder, and its one exception (the registry keeps
  `ResistanceHappenings` as a part) names the new path; `test_player_presentation.gd`, the one
  file that preloaded the path, names the class instead, and `docs/ARCHITECTURE.md`'s listing and
  `GameSave`'s doc follow.
- No skill sentence named the file, the node or the restart's reuse, so no skill changed.

**Verified.** `./tools/check.sh`; `./tools/lint.sh`; `tools/check_layers.py`; the touched suites
by name; the whole suite locally once, shuffled with seed 7 on four shards (the run's state is
loaded by nearly every suite). A free of a `RefCounted` is no parse error, only a runtime one, so
the frees were found by reading the suites for every name bound to a run; that full run passed
every check and still printed engine errors from three frees the reading missed, a run made from a
preload of the script (`test_player_presentation.gd`) and runs freed through untyped lists of
nodes (`test_scene_recipe_task.gd`'s `_free_day()`, `test_scene_recipe_runtime.gd`'s
`_free_task_scene()`). Those three were fixed and rerun shuffled with no engine error. The
player's save is untouched (its md5 before and after).

**Open to overturn** (the builder's choices where the brief was silent): `main` hands the sitting
the fresh run (`_sitting.run = RunState.new()`) rather than dropping it for the next boot's
`take_the_run()` to make, so the restart says what it does where it does it; the old run's escape
section is left as it was, since nothing between the restart and the reload writes the save
(`main` writes only on the flow's own steps, and the flow is RELOADING).

**Not measured:** nothing a player sees changes; the remeasuring step owes nothing for it.
