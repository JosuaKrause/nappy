# M102, the building shows what the city shows, and the escape is in the run log as a day is

Two runs of the escape's first section on `feature/m102-building-shows-what-the-city-shows`, both
started on the right stairwell's top landing (`--start-escape stairwell:right --no-save`), the
section's brief dismissed with `--press ui_accept 0.5`. The masked man waits at the foot of that
shaft until she is in it, gives his notice, and runs up it towards her.

- `rig-095629-seed1908257939-v0.16.0-8-g42b6d63d/badge-masked-man-on-the-stairs.png` —
  `tools/shot.sh … 6 --start-escape stairwell:right --no-save --invincible --press ui_accept 0.5`.
  The screen-edge badge at the bottom edge: the masked man's own silhouette in the red lethal
  ring, the chevron pointing down the flight he is coming up, and his distance under it — the
  badge a day raises for a fire engine, raised here from `InteriorEvents`. The developer readout
  on the right is the escape's own (`section building  180.0s left`, the building tile, the live
  events and the nearest). `run.log` beside it carries the `cue` line the badge wrote; every line
  is stamped `0.0` because `--invincible` stands the section's clock still.
- `rig-095735-seed1674637177-v0.16.0-8-g42b6d63d/run.log` — the same start with no
  `--invincible`, run headless with `--screenshot … --after 18` so the rig drives it (the capture
  itself is refused, since a headless run draws no frame). The run log a day would write, for a
  section: the `start` line, the badge going up and coming down as he comes into view, three
  `near` lines as he closes, the `lost` line naming the result, the section, the reason and what
  was nearest, and the retry's own `start` line, stamped `0.0` on its fresh clock.

`tests/test_interior.gd` ("the building shows what the city shows") and `tests/test_telemetry.gd`
("the escape is in the run log as a day is") are the verification; these show what a person sees
and what the log reads.
