# minty-quail — The GameState stand-in goes: the autoload, the runner's reset and the shared-state skip (run state handed in: the last wave) · 2026-11-04

minty-quail's `run-state-handed-in.md`, its last wave: `project.godot`, `tests/run_tests.gd`,
`tests/shared_state.gd`, `tests/fixtures/run_city.gd`, a comment of `src/autoload/game_state.gd`,
the two null-run guards of `src/autoload/visit_counter.gd`, and the sentences of
`docs/ARCHITECTURE.md`, the godot skill and the verify skill that described the
stand-in.

**Built.** The `GameState` autoload is gone from `project.godot`. The test runner no longer hands
the stand-in to a sitting that enters the tree with no run, nor resets it before each suite; it
configures the visit counter before each suite with no run and no send (`configure(null, null)`),
since the bus reaches the counter in suites that boot no `main`. The counter, configured with no
run, counts under day 0 and sends nothing: its two reads of the run (`_counted_day()` and
`_on_day_started()`) are guarded, since `main` always hands it one.
The shared-state check skips no run field: for each autoload it compares every script variable, the
variables of each part it holds one level down, and its signal connections, beside the engine
settings, the input map, the pressed actions, the root's nodes and every static variable under
`src/`. `RunCity.of_the_run()` is gone. The whole suite list passes with its check count unchanged.
The probes that fixed seed 2 say it is fixed so every machine measures the same runs.

**Rejected.** `configure(null, null)` without the guards raised thousands of `Invalid access` errors
on `Nil`: the counter read the run's day (`'header'`) for everything it counted under the run's own
day before any `day_started` (handlers whose signal carries their day, such as the encounters, do
not), and the run's mode (`'calendar'`) as a day began. A run
the runner made once for the process (`_counter_run`) and handed to the counter before each suite
was rejected in review: it carried state from one suite to the next unseen by the leak check (a
`Node` an autoload holds is compared by identity only), and it leaked at exit when a suite quit the
tree (the quitting-suite fixture's "13 resources still in use").

**Not done:** `RunState` as a `RefCounted`, the file renamed out of `src/autoload/`, and a held
restart handing the sitting a new run; each is a change of its own, kept in the item.
