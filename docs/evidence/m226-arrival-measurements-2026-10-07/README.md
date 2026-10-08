# M226 — Non-pursuer warning and entry measurements

This measurement records the original remaining request: each warned row's badge time and
the gap between creation and entering the view, before and after PR #597. It covers the cyclist,
its pelican picture, fire engine, day-13 column and the loose dog's change to no coming warning.
The ordinary streamed convoy is not a warning-first encounter and is not changed by that request.

## Sources and collector

- Before: `f494956ebc95395f1c848d53b9fc42702aba9c15`, the same baseline as the PR's gold table.
- Current gameplay: `2e21417e96deb1bcf6d69e20690612585c8ecca9`, with the collector below
  added as measurement instrumentation. No gameplay file differs from that revision.
- Collector: [m226_arrival_timing.gd](../../../tests/probes/m226_arrival_timing.gd), identical bytes on
  both revisions, SHA256 `75110083456d9db340b7fb61211e4b238d24d9023c3b7439ee82354bd45442fb`.
- Engine: Godot 4.7.2 stable, macOS Apple M2, headless; 60Hz simulated steps, 30-second limit.
- The before checkout has no tracked modifications. Only the collector and its generated UID
  are temporarily added. Its unrelated `tear_pursuit.gd` and UID are preserved byte for byte.
  No baseline branch or history is changed.

The collector reuses each revision's own `m207_warning_lead.gd` encounter factory and real
`PendingWarning`, `EventInstance`, and `DangerEdge._measure()/announcing()`. Thus “badge removed”
is observed from the actual badge consumer, not inferred from a visibility helper. The camera
is centered on her, 640×360 world pixels, tap mode. She responds instantly at the start by
walking toward, standing, or walking away, at the game's own walking speed. Cyclist/pelican,
loose dog and fire engine use both axes; the engine's horizontal fixture quarter-turns the
existing vertical fixture. The column uses its actual vertical main-road lane. There is no city,
collision, crowd, camera smoothing, input acceleration or active excitement halo in this probe.

“Drawn entry” is the first intersection of the whole camera with an individual current drawing
primitive: the selected directional/stride texture quad, wheels, shadow outline bounds, loose
leash or live caret. The observer reads their drawing inputs independently of placement;
it never calls `footprint_of()`, `drawn_box()` or a family-wide maximum. Texture quads include
transparent padding; this is drawing-geometry timing, not a pixel-alpha or screenshot measurement.
Caret flashing, bob, the actual pelican picture and wheel grounding are included. No empty
space between a separated caret and body is counted as a drawing.

## Results

All times are seconds, rounded to three decimals; the sampling interval is 0.0167 seconds.
[Before output](before.txt) and [current output](after.txt) record all four raw timestamps for
every case: badge start, creation, first drawn entry and badge removal. Each run completes with
28 checks and no failures.

Badge start is 0 for every warned case. The current loose dog instead exists at time 0 and
never raises a badge. “Badge alone” below is creation minus badge start; “badge removed” is
measured from the same encounter start, so it includes any continuation after creation.

| Row / geometry | Response | Badge alone before → now | Placement to drawn entry before → now | Badge removed before → now |
|---|---|---|---|---|
| loose_dog / vertical | toward | 2.267 → no badge | 0.200 → 0.067 | 2.467 → — |
| loose_dog / vertical | standing | 2.267 → no badge | 0.333 → 0.117 | 2.617 → — |
| loose_dog / vertical | away | 2.267 → no badge | 1.033 → 0.400 | 3.400 → — |
| loose_dog / horizontal | toward | 2.267 → no badge | 0.150 → 0.100 | 2.467 → — |
| loose_dog / horizontal | standing | 2.267 → no badge | 0.250 → 0.167 | 2.617 → — |
| loose_dog / horizontal | away | 2.267 → no badge | 0.750 → 0.467 | 3.400 → — |
| cyclist / vertical | toward | 2.133 → 1.000 | 0.200 → 0.067 | 2.333 → 1.083 |
| cyclist / vertical | standing | 2.133 → 1.000 | 0.300 → 0.117 | 2.450 → 1.133 |
| cyclist / vertical | away | 2.133 → 1.000 | 0.667 → 0.217 | 2.850 → 1.283 |
| pelican / vertical | toward | 2.133 → 1.000 | 0.200 → 0.067 | 2.333 → 1.083 |
| pelican / vertical | standing | 2.133 → 1.000 | 0.300 → 0.117 | 2.450 → 1.133 |
| pelican / vertical | away | 2.133 → 1.000 | 0.667 → 0.217 | 2.850 → 1.283 |
| cyclist / horizontal | toward | 2.133 → 1.000 | 0.133 → 0.033 | 2.333 → 1.033 |
| cyclist / horizontal | standing | 2.133 → 1.000 | 0.200 → 0.050 | 2.450 → 1.050 |
| cyclist / horizontal | away | 2.133 → 1.000 | 0.433 → 0.117 | 2.850 → 1.117 |
| pelican / horizontal | toward | 2.133 → 1.000 | 0.133 → 0.033 | 2.333 → 1.033 |
| pelican / horizontal | standing | 2.133 → 1.000 | 0.200 → 0.050 | 2.450 → 1.050 |
| pelican / horizontal | away | 2.133 → 1.000 | 0.433 → 0.117 | 2.850 → 1.117 |
| fire_truck / vertical | toward | 6.283 → 1.000 | 0.183 → 0.100 | 6.500 → 1.133 |
| fire_truck / vertical | standing | 6.283 → 1.000 | 0.267 → 0.150 | 6.600 → 1.200 |
| fire_truck / vertical | away | 6.283 → 1.000 | never → 0.267 | 7.550 → 1.383 |
| military_convoy / day 13 lane | toward | 4.433 → 1.000 | 0.167 → 0.117 | 4.650 → 1.167 |
| military_convoy / day 13 lane | standing | 4.433 → 1.000 | 0.267 → 0.200 | 4.800 → 1.283 |
| military_convoy / day 13 lane | away | 4.433 → 1.000 | 1.150 → 0.833 | 5.950 → 2.200 |
| fire_truck / horizontal | toward | 6.283 → 1.000 | 0.100 → 0.033 | 6.483 → 1.033 |
| fire_truck / horizontal | standing | 6.283 → 1.000 | 0.133 → 0.050 | 6.583 → 1.050 |
| fire_truck / horizontal | away | 6.283 → 1.000 | never → 0.100 | 7.550 → 1.100 |

The engine's old walking-away route parks without its drawing entering the camera during the
30-second observation; its badge nevertheless goes away at 7.550 seconds. This is an observed
non-entry, not a zero-length gap. No placements are refused by these open-ground fixtures.

The warned rows now spend exactly one second with nothing created. Entering the camera is a
separate movement measurement: the column takes 0.833 seconds after creation when she walks
away from it, versus 0.117 walking toward. The badge may remain after a caret first enters,
because the badge consumer asks about the body, not the caret. The table preserves that
difference instead of equating badge removal with drawing entry.

## Reproduction

From the current source checkout:

```sh
tools/test.sh probes/m226_arrival_timing.gd
```

For the before run, use an existing checkout of the exact baseline, with its normal atlas/import
cache prepared by `tools/check.sh`. Copy only the collector above to
`tests/probes/m226_arrival_timing.gd` after confirming that destination does not exist. Run the
same command. Verify its SHA256 matches the value above, then remove only that owned temporary
collector and generated UID. Do not copy current gameplay code or the current encounter factory
into the baseline. The collector selects `follow()` versus `put_up()` and the revision's own
spawn age API by availability; those are its only compatibility branches.

These compact outputs and this collector are the retained measurement evidence. Generic import
and boot output is scratch; no game save is read or written by the test scene.
