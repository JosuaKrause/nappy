# M174, the halo shows what the bar does — a halo beside the man shouting

One `tools/shot.sh` capture on `feature/m174-yeller-cost-and-halo`, seed 4242, day 1, 1280×720.

- `halo-beside-yeller.png` — `--seed 4242 --spawn event:homeless_yeller`, 6 seconds in, no
  `--invincible` (a capture meant to show cost leaves the flag off, since a meter that cannot end
  the day answers nothing about it). `--spawn event:<id>` drops the player beside the first live
  instance of that row; here he is on the arterial's crossing, pacing his beat with the pram
  parked right beside him. His rim reads as a lit, soft-edged glow traced from his own silhouette
  — `EntityHalo`'s ring of offsets — rather than a circle round him, matching "The visual
  vocabulary" in `docs/EVENTS.md`. The debug readout's `nearest` line names `homeless_yeller`
  as the closest live source, `active` (not waiting or telegraphing), confirming the glow in the
  frame is his and not a passer-by's.

This is a picture of the cue reading correctly, not a measurement — the debug readout has no
per-source breakdown to check the net arithmetic against, which `tests/test_halo.gd`'s new checks
hold instead: `net_landed()`'s proportional sharing, the floor at zero, the sum equalling the
bar's own rise, and `_process()` wiring the same net through a real `Baby`.
