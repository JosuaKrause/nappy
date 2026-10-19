# Shared components instead of copies that drift

- **The excitement source is copied.** `CrowdAgent` and `EventInstance` both carry 24 methods with
  the same names and no shared base (`contribution_at`, `expected_gross_at`,
  `_sample_expected_landed`, `accumulate_landed`, `_prune_landed_history`, `_walled_off_now`,
  `wall_grid`, `will_be_lethal`, `set_halo_strength`, ...), documented as "duck-typed with
  CrowdAgent's own copy"; the copies already differ (signatures, extra bookkeeping, the wall cache
  keyed on `_map` in one and `wall_grid()` in the other, a pelican hook in one).
- **Walker and car are one class.** `CrowdAgent` (`src/crowd/crowd_agent.gd`, 4,044 lines, 87 fields)
  switches on `Kind` 66 times; `_cannot_go_on` and `_may_stand_on` mix the car's seal logic with the
  walker's footway logic.
- **Placement has about 25 entry points in four classes**, with self-declared copies:
  `EventManager._where_the_sent_pursuer_starts` copies `ResistanceDirector._draw_arrival_position`
  without its in-view check; `EventManager._a_clear_run_at` equals `ResistanceDirector._a_clear_run`
  plus `_runs_through_the_boundary`; `send_a_pursuer` and `_send_at_her` repeat the same closures;
  `_his_walk_reaches_her` simulates a straight chase only because chasers do not path.
- **Movers do not see each other:** event figures pass through walkers and cars and back.

**Build:** an `ExcitementSource` component both compose, with only the field itself per type; a
`LaneMover` with walker and car strategies; one `SpawnSiting` service with registered legality rules
and a "reaches her" query on the navigator (`world-passability.md`); a shared separation pass over
every mover.
