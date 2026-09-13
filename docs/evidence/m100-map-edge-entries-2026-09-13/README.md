# M100 evidence — people still come out from outside the map

The re-report ([PLAYTEST-69](../../playtests/PLAYTEST-69.md)) of playtest 66's finding, after
M120 (`DECISIONS.md`) had already given an ordinary walker or an off-spine car no room past the
true edge at all. `tests/probes/m100_map_edge_entries.gd` is the diagnosis; the counts below are
its printed output, seed 4242 throughout (`tools/test.sh probes/m100_map_edge_entries.gd`).
"Unsafe" means the agent's own centre is legal by every existing bounds check while its picture —
the actual texture `CrowdAgent._draw_body()` puts on screen — still reaches past the true edge, a
spine car's own tunnel/bridge exception (M94) excluded from every count.

## Which candidate was real

The entry named three: a `_recycle()` landing on the boundary line with the picture straddling it,
a day-start placement (`Crowd.start_day()`, which never goes through `_recycle()`'s own room check)
doing the same, or an agent genuinely left standing past the true edge. The first is what the code
does by construction — beside a plain edge `CrowdAgent._entry_room()` returns `0.0`, so the entry
`reach` in `_recycle()`'s roll caps to zero and the landed point is the true edge coordinate itself,
legal by the old `_entry_band_fits()` (`at >= 0.0`) with the picture on either side of it. The
second showed up too, far more rarely. No case matched the third once the first two were fixed —
every centre stayed exactly where M120 already holds it, in bounds.

## Counts, before the fix

```
walker edge, north: 199/199 entries land within the picture's own clearance (38.0px) of the true edge
car edge, north:    224/224 (off-spine only; the spine's own tunnel traffic is excluded)
walker edge, south: 2/2
car edge, south:    0/0 (off-spine only)
walker edge, west:  179/179
car edge, west:     235/235
walker edge, east:  0/0 (this seed's east region gave the rig too few off-plain-edge samples to
                     say anything at this exact spot; the code path is identical to west's)
car edge, east:     0/0
day start beside the west edge: 0/234 (this seed's west start point did not happen to roll close)
day start beside the east edge: 1/234
```

Everywhere the roll produced a sample, it was unsafe — the boundary-line landing is not a rare
miss, it is what the roll does every time beside a plain edge.

## Counts, after the fix

```
walker edge, north: 0/2
car edge, north:    0/1 (off-spine only)
walker edge, south: 0/3
car edge, south:    0/6 (off-spine only)
walker edge, west:  0/2
car edge, west:     0/5
walker edge, east:  0/2
car edge, east:     0/0
day start beside the west edge: 0/234
day start beside the east edge: 0/234
```

Sample counts drop because the fix makes the unsafe axis-and-direction combination fail its own
roll and the loop settles somewhere else — which is the point: `tests/test_crowd.gd`'s own new
test, `_test_an_entry_beside_a_plain_edge_keeps_room_for_its_own_picture`, pins a **partial** 45px
of room (as M120's own entry test does) rather than a flush edge, so some rolls still succeed
inside the clearance and are refused, and the ones that are not prove the guarantee rather than
assume it — 14 walker and 40 car samples over 400 seeds there, all with the picture inside the map.

## The fix

`CrowdAgent._entry_picture_clearance()` reads the real texture sizes and the same anchor
arithmetic `_draw_body()`/`_car_body_anchor()` use, and returns how far this kind's own picture
reaches past its coordinate on the given axis — the larger of the two directions, so one number
clears either edge. `_entry_band_fits()` and `_keep_within_the_room_beyond_the_map()` ask
`_within_the_map_with_room_for_its_picture()` instead of the old bare `at >= 0.0` wherever
`_entry_room()` grants no room past the edge; `setup()`'s own day-start placement loop asks the
same question, since it never went through the room check at all.

## `after-north-edge-burst/`

The whole run folder for `tools/shot.sh screenshot.png 8 --seed 4242 --day 1 --invincible --spawn
corner:nw --walk west --layers 2,3 --press snapshot_burst 3`, taken after the fix: `run.log`,
`maps/day01-attempt1.png`, the 36-frame burst under `asked/burst-5865113-001/` with its
`burst.json`, and `screenshot.png`, the frame `tools/shot.sh` saved at the end of the run. She
walks from just inside the north-west corner to tile (0,1) — the sidewalk row against the true
north edge — and stands there for the rest of the burst. Across all 36 frames nobody's picture
reaches into the mountain band above the green boundary line: every walker, the delivery van and
the mother herself stay fully on the pavement or the road. This is a corroborating capture rather
than a caught-in-the-act one: as M120's own evidence README notes for the same reason, a burst
posed to *show* a fresh entry would need to catch one recycling during the window it happens to be
in, which the diagnosis above answers directly instead.
