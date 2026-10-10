# snowy-kestrel, a red-arrow task's destination without a chalk mark — stills, 2026-10-10

**Claim.** At v0.26.0 (`a5bfee58`) the destination of every task whose contact stands on a bare
point — day 9's district door, day 11's loudspeaker mast, day 12's swing and the last night's
power station door — draws the chalk-mark picture under the red arrow, and once the task is done the
touched chalk picture stays there. With `ContactPoint.draws_a_mark()` answering true only for a
pickup, those destinations show the item itself with the arrow on it, and the alley pickup's mark
and its touched picture are unchanged. Days 6, 7, 8, 10 and 13 ride an event (the man shouting,
the van, the burnt shell, the neighbor, a roadblock) and drew no chalk before either.

**Each file is one sheet**: a 320×220px crop of the game's 1280×720 frame around the destination,
scaled 2× with nearest-neighbour, the v0.26.0 frame on the left and this branch's on the right,
taken at the same moment of the same scene.

| File | Scene and moment | Shows |
|---|---|---|
| `day-09-district-door.png` | `task-09-crossing.json`, 17s | the gatehouse with the arrow, before the crossing |
| `day-09-district-door-done.png` | `task-09-crossing.json`, 20s | the gatehouse at the top edge once she has crossed: the touched chalk there before, nothing after |
| `day-11-mast.png` | `task-11-mast.json`, its `capture_at` | the mast's foot with the arrow |
| `day-12-swing.png` | `task-12-swing.json`, its `capture_at` | the swing's base with the arrow |
| `day-14-station-door.png` | `task-14-last-night.json`, its `capture_at` | the station door with the arrow |
| `pickup-day-09-mark.png` | `task-09-crossing.json`, 0.1s | the alley's chalk mark, untouched, unchanged |
| `pickup-day-09-mark-read.png` | `task-09-crossing.json`, its `capture_at` | the read mark's touched picture, unchanged |

**How they were taken.** Stills from `tools/scene-recipes.sh --screenshots --recipe
scene-recipes/task-09-crossing.json --recipe scene-recipes/task-11-mast.json --recipe
scene-recipes/task-12-swing.json --recipe scene-recipes/task-14-last-night.json`, run once in a
detached checkout of `v0.26.0` and once on this branch, plus two day-9 stills at 17s and 20s from
`tools/shot.sh <out> <seconds> --recipe scene-recipes/task-09-crossing.json --recipe-mode scripted
--player-view --no-save`, since the scene's own capture moment has the gatehouse off screen. Each
recipe fixes the seed, the city stretch and the walk. The crops were cut from those full frames
with Pillow; the full frames are not kept, as nothing outside the crops bears on the claim.

**Limits.** A still shows one frame: the chalk picture's alpha flickers, so its brightness in a
"before" crop is that frame's. The sheets show four scenes on one seed; that no perform contact on
any task day draws a chalk picture, untouched or done, is held by `tests/test_destination_drawing.gd`
rather than by these pictures.
