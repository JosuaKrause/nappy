# guard-path: the guard set on her walks round a building to her, 2026-10-11

**Claim.** A guard set on her the way day 13's done task sets its waiting guard on her
(`EventInstance.notice_her_at()`), from a spot with a building across his straight line, walks round
the building toward her instead of pressing against its wall: north of her building, along its west
side, and round its south-west corner to her front door.

**Forcing edit.** `forcing.patch` is for the capture only and is never on the branch. Reaching day
13's real task in a capture means walking to the mark and then to a roadblock, so instead it makes
`src/main.gd` set the alley robbery row (the row the task's guard is) on her one second into the
day, with `notice_her_at()`, from the first spot 7 to 15 tiles from her that she can walk to in at
most 30 tiles, with no clear line to her, and from which a chase straight at her, sliding along walls
(`EventInstance.walkable_step_on()`), never comes within his 116px stand-off of her. On seed 4242's
day 13 that is tile (76, 75), 309px from her at (80, 84), a walk of 15 tiles, behind the building
whose front door she stands at. He is created in her view, which the real guard never is: the
pop-in is the forcing's, not the game's.

**The burst.** A real burst (`--press snapshot_burst 1.0`, 17 frames over 3.0s from one second into
the day, `burst.json` the timing record). Five of the frames are kept, each cropped to the 560x400
pixels round the building (offset 300, 0 of the 1280x720 frame); the elapsed times are from the
burst's own start. `--zoom 0.5` shows twice her ordinary view each way, so the robber is in the
picture while he is still outside her ordinary view: the round badge with a red pointer and a
distance over him is the screen-edge badge (`DangerEdge`), drawn at the edge of her ordinary view.
She stands still in front of her door throughout, and `--invincible` keeps the clock at 3:00.

- `frame-0001.png` (0.20s): he stands north of the building, on the sidewalk above its north-west
  corner, his badge over him, 14 m off.
- `frame-0005.png` (0.92s): he has stepped to the building's north-west corner, at the top of the
  sidewalk along its west side.
- `frame-0009.png` (1.57s): he is walking down the west side of the building, beside its wall, 10 m
  off.
- `frame-0013.png` (2.22s): he is further down the west side, level with the building's lower
  floors and past the badge's ring, so drawn without it.
- `frame-0017.png` (2.87s): he has rounded the south-west corner onto the sidewalk in front of the
  building, running toward her with the doubled red caret over him.

Without the change he comes straight at her from (76, 75) and stops against the building's north
wall; `tests/test_day13_guard.gd`'s check with a building between them holds that on a spot chosen
the same way, where without the pathing he ends 147px from her against a 116px stand-off.

**Limits.** One seed, one spot, her standing still. The burst shows the direction of his walk; the
suite holds that he reaches her stand-off, from a spot round a building and from another roadblock
1,778px away.

**Reproduce**, from the branch at the commit that adds this folder:

```sh
git apply docs/evidence/guard-path-2026-10-11/forcing.patch
tools/shot.sh /tmp/guard-path.png 5 --seed 4242 --day 13 --invincible --no-save --zoom 0.5 \
    --player-view --press snapshot_burst 1.0
git checkout src/main.gd
```
