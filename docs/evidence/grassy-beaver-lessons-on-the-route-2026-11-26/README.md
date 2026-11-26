# grassy-beaver, the lessons on the route: day 1's lessons in the game

**Claim:** on seed 4431's day 1, each lesson's row stands where the lessons on the route put it,
lesson (3)'s dog walker comes down the line's sidewalk at her on its street, and her walk from
lesson (4)'s zebra over lesson (5)'s and past the yeller of lesson (6) goes as the lessons lay
it. Dated runtime evidence of one build and one seed, not a visual reference.

**Source:** the branch `feature-grassy-beaver-lessons` at d14e8837e (the merge of main carrying the
car-free start), with the working tree as committed alongside this folder. Windowed captures through
`tools/shot.sh` at 1280x720, `--invincible` so the day holds still, the developer readout on.

| File | Command | Shows |
|---|---|---|
| `lesson-2-market-stall.png` | `tools/shot.sh out.png 3 --seed 4431 --spawn event:market_stall --invincible` | lesson (2): the market stall on the west sidewalk of its street, across the carriageway from her line on the east sidewalk; she is dropped beside it on the carriageway |
| `lesson-3-dog-walker-burst-frame-0019.png`, `lesson-3-burst.json`, `lesson-3-run-log-excerpt.txt` | `tools/shot.sh out.png 11 --seed 4431 --spawn event:market_stall --walk 1e10s --invincible --press snapshot_burst 5` | lesson (3): walking south down the line's sidewalk, the dog walker the director sent the moment she was on lesson (3)'s street meets her at tile (61,109) (the run log's `ahead` and `near` lines); lesson (4)'s delivery van shows at the left, on the sidewalk she arrives toward |
| `lesson-4-delivery-van.png` | `tools/shot.sh out.png 3 --seed 4431 --spawn event:delivery_van --invincible` | lesson (4): the van on the north sidewalk of the street west of the box, just past the box, so the line crosses that street's carriageway at the box's zebra |
| `lesson-6-yeller.png` | `tools/shot.sh out.png 3 --seed 4431 --spawn event:homeless_yeller --invincible` | lesson (6): the yeller (top, arm raised) on the line's sidewalk of the street before the park's; the spawn put her beside the nearest event, a mouth seal's café tables |
| `lesson-4-to-5-burst-a.mp4`, `lesson-4-to-5-burst-a.json`, `lesson-4-to-5-burst-a-frame-0012.png`, `lesson-5-to-6-burst-b.mp4`, `lesson-5-to-6-burst-b.json`, `lesson-4-to-6-run-log-excerpt.txt` | `tools/shot.sh out.png 17 --seed 4431 --spawn event:market_stall --walk 1e8s7w --invincible --press snapshot_burst 6.5 --press snapshot_burst 12.5` | lessons (4) to (6) in motion, two bursts of one walk. Burst A (25 frames): down lesson (3)'s street past its dog walker, over lesson (4)'s zebra at (61,114) with the delivery van on the far (north) sidewalk west of the box (frame 12, the moment before she steps on), and onto the south sidewalk, the ground past the crossing with no cars, where the car-free start lets cars in. Burst B (24 frames): from (51,117) west along the line's sidewalk, over lesson (5)'s zebra at (45,117), past the yeller (lesson (6)), who paces with his arm raised from (42,117) to (43,117) as she comes |
| `lesson-5-horn-burst-c.mp4`, `lesson-5-horn-burst-c.json`, `lesson-5-horn-burst-c-frame-0033.png`, `lesson-5-horn-run-log-excerpt.txt` | `tools/shot.sh out.png 9 --seed 4431 --spawn event:delivery_van --walk 1s7w --invincible --press snapshot_burst 2` | lesson (5) with a car: from (52,117) west to lesson (5)'s zebra; on it a car sounds its horn at her at (44,117) (the run log's `crowd` line and the mark over her head that follows), so the cars are let in by then and one is coming to that crossing. Frame 33 has her on the zebra with the yeller beside her |

The run log's plan lines for this seed put the stall at (57,94), the van at (55,113) and the yeller
at (41,117). The bursts and their runs are at 9f877a6f1, with only test files changed in the working
tree. **Limits:** the lesson (3) burst kept one frame of its 36, the one where the dog walker is
beside her; the three bursts for lessons (4) to (6) are kept as their clips, with one frame each of
A and C. The other pictures are stills, which show where a row stands and nothing about motion.
The two bursts of one walk leave a gap from (60,117) to (51,117), which they do not show. No car
is in any frame at lesson (5)'s zebra: the horn in burst C is the evidence that one was coming, and
the frames at about 8 frames a second do not show it. On this seed the yeller's beat reaches
lesson (5)'s zebra, so she meets him on the crossing with cars rather than on the street after it;
one seed shows that it can happen, not how often. The second dog walker on the walk home is not
shown; how often it is met is the probe `tests/probes/grassy_beaver_dog_walkers.gd`'s, and
`tests/test_tutorial_dog_walkers.gd` holds it (the record grassy-beaver-golden-puffin).
