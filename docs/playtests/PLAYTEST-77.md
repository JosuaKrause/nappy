# Playtest 77 — 2026-09-15

A desktop run on `v0.10.7-107-gc7dfc4ed`, the `main` that carries M152's landing fix, seed
3126506586, day 1, three minutes after the queue's other pull requests of the day were
merged. One finding, with a burst the player asked for.

## Cars are still jumping around

> "2026-09-15/run-202436-seed3126506586-v0.10.7-107-gc7dfc4ed/asked/burst-25017518-001 that
> shows that cars are still jumping around"

Said on 2026-09-15 after the M152 jump probe on this build had come back identical to the
filed after-the-fix run (no landing retreats in view). The run folder is copied whole to
`docs/evidence/m152-about-face-2026-09-15/run-202436-seed3126506586-v0.10.7-107-gc7dfc4ed/`;
the burst is 36 frames over 3.0 s at 12 fps, `burst.json` carries the capture times.

What the frames show. She stands at tile (97,103) on a pavement; the north-south street one
junction east of her is sealed about five tiles south of the junction by a burst water main.
A car stopped on the zebra just south of that junction, at about tile (99,102), keeps its
position along the street for the whole burst and slides sideways between the two lane
centres, about 62 px peak to peak with a period near 0.7 s — its tail lights measured at 753,
768, 783, 795, 779, 765, 750, 734 px and back, frame by frame. At frame 15 its picture flips
from facing south to facing north in one frame and then holds north while the sliding goes
on. Southbound cars queue behind it in the west lane and overlap each other (frames 25 to
27). So the second shape playtest 76 reported — a car that reverses on the spot instead of
routing a U-turn — is this: the reversal repeats once a stride on a stopped car at a seal, and
each one carries the car toward the other lane until the next. Answered on the same day's branch:
`DECISIONS.md`, M152, the about-face is planned and the morning is unpacked early.
