# Shared components instead of copies that drift

- **The excitement source is copied.** `CrowdAgent` and `EventInstance` both carry 24 methods with
  the same names and no shared base (`contribution_at`, `expected_gross_at`,
  `_sample_expected_landed`, `accumulate_landed`, `_prune_landed_history`, `_walled_off_now`,
  `wall_grid`, `will_be_lethal`, `set_halo_strength`, ...), documented as "duck-typed with
  CrowdAgent's own copy"; the copies already differ (signatures, extra bookkeeping, the wall cache
  keyed on the two points in `EventInstance` and on the two points and `_map` in `CrowdAgent`, a
  pelican hook in one).
- **The walker and the car share one node that also draws them.** `CrowdAgent` is the lane mover
  both kinds share, with what only one kind does in its `WalkerStrategy` or `CarStrategy`; the same
  node holds the excitement field and the drawing, and the drawing chooses each kind's
  picture, sector, redraw key, bob and paint by asking `kind`. Its moved docstrings carry the
  history `comments.md` asks to move to the records.
- **Placement has about 25 entry points in four classes**, with self-declared copies:
  `EventManager._where_the_sent_pursuer_starts` copies `ResistanceDirector._draw_arrival_position`
  without its in-view check; `EventManager._a_clear_run_at` equals `ResistanceDirector._a_clear_run`
  plus `_runs_through_the_boundary`; `send_a_pursuer` and `_send_at_her` repeat the same closures;
  `_his_walk_reaches_her` simulates a straight chase only because chasers do not path.
- **Movers do not see each other:** event figures pass through walkers and cars and back.

**Build:** an `ExcitementSource` component both compose, with only the field itself per type; a
`LaneMover` base holding the shared lane movement, with `CrowdAgent` on it as the crowd member (its
excitement methods, halo, caret and drawing), the drawing in a walker look and a car look, and the
present-tense pass over the moved docstrings; one `SpawnSiting` service with registered legality rules
and a "reaches her" query on the map's one `Navigator` (`WorldMap.navigator()`); a shared separation pass over
every mover.

**Open question, the orchestrating session's carry-over from minty-quail-5 rather than the player's
ask:** whether the crowd's lane movement goes onto the map's one `Navigator`. It is not part of the
walker-and-car split, because a lane-following held step is a different motion model from the
navigator's swept step, so moving it cannot stay at test parity; it sits beside the separation pass,
which reaches the same movers.
