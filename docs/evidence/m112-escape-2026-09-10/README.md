# The escape scene, walkable — capture session

`tools/shot.sh` against a real display — the capture guard
(`can_photograph(DisplayServer.get_name())`) answered yes throughout, so no capture here was
skipped for lack of one. The building is one map holding seven parts (see `InteriorMapPlan`'s own
doc); `--start-escape <part>` teleports straight to any of them, so every capture below is a boot
and a short wait rather than a walk from her own door, and none took longer than six real seconds.

- `hallway-third.png` — `--start-escape`, 2s wait. Her own door mid-hallway, the north wall's lift
  and windows, both lamps, and the chandelier's light pool.
- `hallway-second.png` — `--start-escape floor:2`, 2s wait.
- `hallway-first.png` — `--start-escape floor:1`, 2s wait. Byte-identical to the other two
  hallways' own captures, since all three share one layout and a centred camera shows nothing that
  distinguishes them — expected, not a capture defect.
- `stairwell-left.png` — `--start-escape stairwell:left`, 2s wait. The shaft's own top landing at
  its door, the first flight's treads descending toward the turn, its newel, and the rail running
  unbroken across the tile seams.
- `stairwell-right.png` — `--start-escape stairwell:right`, 2s wait. Byte-identical to the left
  shaft's own capture for the same reason the hallways are.
- `lobby.png` — `--start-escape lobby`, 2s wait. The barricaded entrance behind its lamps, the dead
  lift beside it, and both stairwells' doors at the south edge's ends.
- `basement.png` — `--start-escape basement`, 2s wait. The brick-walled stretch nearest the entry,
  a puddle, and the jog toward the next stretch.
- `stairwell-left-flight-walk-burst.mp4` — `--start-escape stairwell:left --walk 1@135@6e --press
  snapshot_burst 1.5`, 6s wait, a 36-frame/3s burst converted with `tools/clip.sh`. One second at a
  135° bearing onto the first flight tile, then six seconds holding plain east: the redirect
  carries her down the first flight, across the turn, down the back flight and onto the second
  floor's own landing — a screen-axis press walking the tile's own diagonal slope the whole way,
  never sideways off the treads.

## What this capture session found

The first attempt at the burst above showed her standing still at the shaft's own top landing for
the whole three seconds despite the walk script, both indoors and — as a control — with the same
bearing script run outdoors, where it visibly carried her most of a city block. The difference was
not the redirect: a diagonal flight tile touches its own diagonal neighbour at a single corner
point, and `InteriorScene._rebuild_collision()` was blocking both cells flanking that corner with a
full 32px `RectangleShape2D` on each side, pinching the gap to nothing — no radius of circular body
can cross a gap with zero width. `InteriorMap._mark_diagonal_clearances()` now frees both flanking
cells of every diagonal adjacency in the plan after it is laid, and `_rebuild_collision()` skips
them the same way it already skips floor; `tests/test_interior.gd`'s
`_test_every_diagonal_step_has_both_its_pinch_corners_cleared` is the headless regression test,
asserting the data rather than real collision, since no suite in this repo drives
collision-checked `move_and_slide()` movement headlessly (see that test's own doc for why). The
capture above is the fix confirmed on screen.
