# M199: the closing roadblock's own picture and badge, and its guards' two options

Claim: the closing roadblock has a picture and a screen-edge badge of its own, unlike the open
roadblock's, and stands wall to wall across a street of either axis; and the two places its guards
could stand, as built and as the region wall's guards do, look as shown. Limits: stills, a cold
row at heat 0, day 13 on the full city of context seed 1917501, no walk; they show where the bodies
and guards stand and how the pictures read, not how a run plays.

- `source-sheet.png`: the pictures themselves through the engine's own SVG parser at 3x, the open
  roadblock above and the closing one below; left to right, a band of seven broadside segments
  between two end posts, the end-on segment, the badge icon at 3x and at 1x, and the band at 1x.
  Made by `sheet.gd` (kept here) in an empty scratch project:
  `Godot --headless --path <empty project> --script sheet.gd -- art/events <out.png> 3`.
- `guards-in-the-road.png`: as built. Top, a closing roadblock across a north-south street;
  right of her, one across the east-west street she stands on, drawn end-on; bottom, the open
  roadblock, its far sidewalk free. Each closing roadblock's two guards stand in the road, one on
  each side of the band at the street's middle.
- `guards-on-the-sidewalks.png`: the other option, four guards, one on each side of the band on
  each sidewalk, as a region wall's stand. Drawn from a temporary change to
  `RoadblockLook._draw_posted_guard()` that drew each posted guard twice, 64px either way across
  the street (the two sidewalks' middles), for the closing roadblock only; the change is not
  committed.

Source: the branch at the merge of main 19bf66d6b (`0b9a1caf7`). Command, for both stills:
`tools/scene-recipes.sh --recipe recipe.json --output <dir> --screenshots` (`recipe.json` is kept
here; each still is that run's `both.png`).

## The placement measurement

`placement-rows-*.txt` are the `RD`, `RV` and `RK` lines of `tests/probes/placement_rows.gd` (18
seeds, heat 0, summed over the seeds; its header says what each line counts), the rest of the run's
output left out. `RV day row view count` is what the record's table reads, view 0 being her
routes' own ground:

- `placement-rows-main-3db9e886c.txt`: main at `3db9e886c` (day one's tutorial route merged),
  days 1 to 14, run from a copy of that tree.
- `placement-rows-branch-fa22fbda5.txt`: the branch at `fa22fbda5` (the route bag holding no
  closing-roadblock marble; main merged only to `89fbd3923`, so without the tutorial route), days 1
  to 14.
- `placement-rows-branch-0b9a1caf7-day1.txt`: the branch with main merged to `19bf66d6b`, day 1
  only (the probe's day loop cut to day 1 in an uncommitted copy), which matches main's day 1 line
  for line.

Command: `tools/test.sh probes/placement_rows.gd`, in a checkout of each revision
(`git fetch origin refs/pull/1752/head` for the branch's).
