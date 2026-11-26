# grassy-beaver, the lessons on the route: day 1's lessons in the game

**Claim:** on seed 4431's day 1, each lesson's row stands where the lessons on the route put it,
and lesson (3)'s dog walker comes down the line's sidewalk at her on its street. Dated runtime
evidence of one build and one seed, not a visual reference.

**Source:** the branch `feature-grassy-beaver-lessons` at d14e8837e (the merge of main carrying the
car-free start), with the working tree as committed alongside this folder. Windowed captures through
`tools/shot.sh` at 1280x720, `--invincible` so the day holds still, the developer readout on.

| File | Command | Shows |
|---|---|---|
| `lesson-2-market-stall.png` | `tools/shot.sh out.png 3 --seed 4431 --spawn event:market_stall --invincible` | lesson (2): the market stall on the west sidewalk of its street, across the carriageway from her line on the east sidewalk; she is dropped beside it on the carriageway |
| `lesson-3-dog-walker-burst-frame-0019.png`, `lesson-3-burst.json`, `lesson-3-run-log-excerpt.txt` | `tools/shot.sh out.png 11 --seed 4431 --spawn event:market_stall --walk 1e10s --invincible --press snapshot_burst 5` | lesson (3): walking south down the line's sidewalk, the dog walker the director sent the moment she was on lesson (3)'s street meets her at tile (61,109) (the run log's `ahead` and `near` lines); lesson (4)'s delivery van shows at the left, on the sidewalk she arrives toward |
| `lesson-4-delivery-van.png` | `tools/shot.sh out.png 3 --seed 4431 --spawn event:delivery_van --invincible` | lesson (4): the van on the north sidewalk of the street west of the box, just past the box, so the line crosses that street's carriageway at the box's zebra |
| `lesson-6-yeller.png` | `tools/shot.sh out.png 3 --seed 4431 --spawn event:homeless_yeller --invincible` | lesson (6): the yeller (top, arm raised) on the line's sidewalk of the street before the park's; the spawn put her beside the nearest event, a mouth seal's café tables |

The run log's plan lines for this seed put the stall at (57,94), the van at (55,113) and the yeller
at (41,117). **Limits:** the burst kept one frame of its 36, the one where the dog walker is beside
her; the other three are stills, which show where a row stands and nothing about motion. Lesson
(5), the crossing with cars, has no capture: on this build the cars are held until she is past
lesson (4)'s zebra (the car-free start) and nothing here walked her there. The second dog walker
on the walk home is not shown; how often it is met is the probe
`tests/probes/grassy_beaver_dog_walkers.gd`'s (the record grassy-beaver-golden-puffin).
