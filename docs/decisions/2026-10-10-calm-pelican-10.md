# calm-pelican — Small corrections from the re-review · 2026-10-10

From the re-reviews of PRs #580, #553, #596, #629, #605 and #547, and one gap found while building
#642.

**Built in PR #647**, one commit each:

- **#580:** the comments in `tests/test_crowd_closures.gd` and `tests/probes/m100_map_edge_entries.gd`
  name the room a spine car keeps (`CrowdAgent.TUNNEL_ROOM`, `BRIDGE_RUN`, `TUNNEL_ENTRY_ROOM`,
  `BRIDGE_ENTRY_MIN`) rather than an overrun by `Tuning.OUT_OF_SIGHT`. The camera's freedom past the
  city's edge, which #580 never described or showed, is captured at the east edge and the bridge in
  [calm-pelican-camera-edge-2026-10-10](../evidence/calm-pelican-camera-edge-2026-10-10/README.md)
  and put to the player in the review item
  [calm-pelican](../review/2026-10-10-calm-pelican.md).
- **#553:** `docs/TELEMETRY.md`'s `_draw()` paragraph keeps its argument and points at
  [M159-7](2026-09-19-M159-7.md) and its evidence for the measured figures.
- **#596:** `tools/goatcounter.py`'s `fetch_hits` raises `GoatCounterError` when a page says `more`
  but none of its hits has a `path_id`, rather than ending quietly; an empty page or one of only
  repeats still stops, the existing guard against a server that says `more` forever.
- **#629:** every `printf … | grep -q` under `pipefail` in the tool scripts is a here-string, which a
  grep exiting early cannot turn into a false failure.
- **#605:** the southeast pelican's far foot is the darker `#b8683a` its record gives the far leg, in
  both frames; before and after renders are in
  [calm-pelican-se-far-foot-2026-10-10](../evidence/calm-pelican-se-far-foot-2026-10-10/).
- **#547:** the `BABY_CUE_LIFT` comment names `PRAM_ART_HEIGHT` rather than typing 30px.
- **Found building #642:** `docs/TELEMETRY.md`'s raw frame traces section says a trace whose window
  is covered records no frames.

**Chosen where the item was silent, open to overturn:** the captures use `--spawn edge:e` and
`edge:s` (the dev rig's bridge target) rather than `corner:se`; `lint.sh`'s
`head -n 1 … | grep -qF` was converted too, having the same hazard.
