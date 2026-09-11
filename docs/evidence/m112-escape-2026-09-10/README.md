# The escape scene, walkable — capture session

`tools/shot.sh` and a windowed boot, both `--start-escape`, against a real display — the capture
guard (`can_photograph(DisplayServer.get_name())`) answered yes throughout, so no capture here was
skipped for lack of one.

- `floor-3-start.png` — `--start-escape`, 1.5s wait, no walk. The third floor's hallway at boot:
  her own door mid-hallway (the wall carries the lift and four windows), the chandelier's light
  pool, and both stairwells with their treads, rails, newels and the open shaft between each
  flight pair.
- `floor-3-left-stairwell.png` — `--start-escape --walk 5w2s2e`, 9s wait. West to the hallway's own
  end, south onto the left stairwell's door, east across its first flight to the landing —
  carrying the baby, standing on `stair_landing.svg` with the rail and newel drawn over the flight
  behind her.
- `left-stairwell-flight-burst.mp4` — `--start-escape --walk 5w2s3e --press snapshot_burst 7`,
  11s wait, converted from a 36-frame burst with `tools/clip.sh`. She crosses the first flight's
  three tread tiles while the camera pans to keep her in frame.

## What is not here, and why

Floors below the third, and the basement's own exit, are not captured. Reaching them from a cold
boot needs a `--walk` script chained through 3–4 stairwell traversals, each a fixed sequence of
whole-second holds overshooting into a wall on purpose (`--walk`'s own script format takes whole
seconds only, so a hold long enough to reliably reach a landing works the same way a `--flee`
timeout margin does — err long, let the collision stop her exactly, never err short and miss the
tile) — around 13 real seconds per floor. Windowed captures at that length were not reliable in
this session: the process's own accumulated frame time stopped advancing partway through
(consistently around the same in-scene position, `day 1` sleepiness reading `5` regardless of how
much longer the wait was extended, from 16s up to 36s) while the wall-clock `--after` timer kept
running and eventually took the shot anyway — the windowed-run stall the verify skill names, where
a window not holding focus stops getting frames, and a longer wait cannot fix a process that is not
advancing. The three captures above each finish inside roughly nine to eleven real seconds and were
reliable across repeats; nothing scripted past about ten seconds was.

This is a gap in the *pictures*, not in the *check*: every floor, both stairwells' switchback
layout, the anti-shortcut gap between a door and its own lower landing, and a full walk from the
third floor to the basement's exit down each stairwell are already asserted headlessly in
`tests/test_interior.gd` (`_test_a_rig_walks_both_stairwells_to_the_exit` and the floor-plan tests
beside it), which steps `InteriorScene`'s own transition logic directly rather than depending on
real time elapsing in a window. What a screenshot alone could still answer — whether the deeper
floors and the exit *read* right on screen — is open for a session with a display available for
longer stretches at once.
