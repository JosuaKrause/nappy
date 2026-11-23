# polite-tapir — The row reads the view's least boundary from Offscreen · 2026-11-23

**The ask.** The standing layer breaks of the design review, which the player approved
(inbox #1268 in olive-ferret), are each fixed, moved in the map or declared permanent. This is the
first of the design's nine pull requests: a catalogue row (data) named the siting (world) to read
one number.

## What was built

- **`EventDef.warning_time()` and `nearest_it_is_created()` read `Offscreen.min_boundary()`**
  (the view's half height, 180 px, the floor anything arriving from off screen is created at)
  where they read `SpawnSiting.least_distance()`. `Offscreen` is data, static and a pure function of
  `Tuning.VIEW_HALF_EXTENT`; `least_distance()` was one line returning the same call, and
  `nearest_it_is_created()` already called `Offscreen.min_lead()` two lines further down. The two doc
  comments say the same.
- **The `SpawnSiting` entry is deleted from `tools/layer_map.py`**, and the item file's two clauses on
  it are gone: the one that listed the break and the one that handed it to the events' interface rows.

## Verified

- `tests/probes/row_fingerprint.gd` run on `origin/main` and on the head: the `RF` lines are
  identical (a diff of the two files is empty).
- `tools/check_layers.py` passes with the entry gone and `--list` names nothing of `SpawnSiting`;
  `tools/cost-table.sh --check`, `test_events_catalogue`, `test_events_costs` and
  `test_no_pop_in` pass.

## Left for the queue

- **`SpawnSiting.least_distance()` is now a second name for one number**, a pass-through its readers
  would not miss (designing-classes, "An interface is judged by its callers"). Its removal reaches
  `spawn_siting.gd`, `event_spawner.gd`, five suites and a probe, a sentence `tools/cost_table.gd`
  prints and the events skill's `references/warned-first.md`, so it is an entry of its own.
  Plainer alternative, not taken: delete it in this pull request, which widens a two-line fix to
  about ten files.
