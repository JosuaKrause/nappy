# Small corrections from the re-review

**Low, each one line or a few · from the re-review of the PRs since v0.25.0.**
- **#580:** `tests/test_crowd_closures.gd` and `tests/probes/m100_map_edge_entries.gd` say a spine
  car overruns the map edge by `Tuning.OUT_OF_SIGHT`; cars now keep `CrowdAgent.TUNNEL_ROOM` /
  `BRIDGE_RUN` on the way out and `TUNNEL_ENTRY_ROOM` / `BRIDGE_ENTRY_MIN` on the way in. Name those.
- **#580:** the camera no longer stops at the city's edge (the land past it is painted for any
  view), which the PR neither described nor showed. File a review item with a capture at an east or
  west edge and at the bridge (for example `--spawn corner:se`).
- **#553:** `docs/TELEMETRY.md`'s paragraph beginning "The game's own `_draw()` overrides each start
  with" quotes measured figures (calls a frame, nanoseconds, milliseconds); keep the argument (about
  twenty `_draw()` calls a frame against some 270 timed bodies, one guarded read each when the record
  is off) and point at [M159-7](../../decisions/2026-09-19-M159-7.md) and its evidence for the numbers.
- **#596:** `tools/goatcounter.py`'s `fetch_hits` ends paging quietly when a page's hits all lack
  `path_id` while `more` is true; raise `GoatCounterError` instead.
- **#629:** the `printf '%s' "$x" | grep -q` pattern, which `pipefail` turns into a false failure
  when grep exits early, remains in `tools/test_cli_help.sh`, `tools/lint.sh`, `tools/prune-merged.sh`, `tools/test_lib_agent_role.sh` and `tools/test_rules_hooks.sh`; use here-strings
  (`grep -q … <<<"$x"`) in one pass.
- **#605:** the southeast pelican's far foot keeps the near leg's `#e0843a` in
  `art/events/pelican_cyclist_front_diagonal.svg` and `_b.svg`, where every other view and the
  record give the far leg the darker `#b8683a`; recolour it and re-render (a drawing change, so the
  agent is Opus, and the player approved the drawing as it is).
- **#547:** the `BABY_CUE_LIFT` comment in `src/player/stroller.gd` types "30px", which
  `PRAM_ART_HEIGHT` now names.
- **Found building #642:** `docs/TELEMETRY.md`'s "Raw frame traces" section does not say that a
  trace taken while the game's window is covered records no frames at all (its summary shows 0
  intervals).
