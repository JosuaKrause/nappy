# M129 — a spent park is closed

Superseded once already: the first pictures here showed every used calm area fenced off, which the
player turned down (`docs/playtests/PLAYTEST-140.md`, "Then, on the first pictures of a spent park"):

> "a park that was used should be shut down, yes, but by placing events in it how it was before.
> where does this barrier thing come from? doing it for one park, sure, more towards the later
> stages of the game once but not for regular" · "yes, the corners look wrong, too"

The design is now: **every** used calm area is spoiled with events, the way it always was, and the
day's route tree plans around it — no barrier, ground stays walkable. **One** area, at most once a
run and never before act III, gets `ParkClosure`'s fence instead. These three stills are of that one
fenced park, with the corner defect the player flagged fixed.

## What was wrong with the corners, and the fix

The old `ParkClosure.mouth_centres()` covered a long run with several `Tuning.STREET_WIDTH`-wide
lines, spaced to overlap on purpose so panels never left a gap — which read as doubled rails
wherever they overlapped, and let two edges' lines both reach into the same corner tile and cross
there instead of meeting. Now:

- `RoadClosure.barrier_width()` (default: a street's own width) is overridden on `ParkClosure` to
  return the *run's own length*, so `City._spawn_barrier()` tiles one continuous rail across exactly
  that length — no overlap, no gap, one line per side.
- `UP`/`DOWN` runs keep the whole side, corner tiles included; `LEFT`/`RIGHT` runs stop one tile
  short of each end, so the two edges never both claim the same corner tile. See
  `ParkClosure._entrance_runs()`.

## Why these are not a `tools/shot.sh` capture

Reaching "a day with a park she has already used" needs at least one full day actually played to a
win, and reaching "act III, with a fence chosen" needs several — no existing dev flag plays a day
through for a screenshot rig, and `--route calm,home` (`RouteRig`) quits the process the moment one
day ends rather than carrying into the next. `src/dev/` is also fenced off to this PR (a live agent,
M204, owns it). So these are a small one-off script, not committed, that builds the same real `City`
`tests/test_spent_park.gd`'s own scene test does and hands it the same state `Main._start_day()`
would after several days of play: a used calm area (`CityMap.set_spent_calm()`) and "nothing fenced
yet, act III" (`CityMap.set_fenced_park_state()`), then lets the real `City.start_day()` →
`ClosurePlanner.calm_to_shut()` → `ParkClosure` chain decide and draw the rest. A plain `Camera2D`
(the same zoom `Main._new_boot_camera()` uses) stands in for the player.

Seed 14040, day 9, the nearest calm area to the doorstep handed over as used; it was both taken off
the route tree and chosen as the run's one fenced park.

## The stills

- `corner-nw.png` — the fenced park's north-west corner: the top rail keeps the whole side including
  the corner tile, the left rail stops flush against it, one sign per side, no overshoot.
- `corner-se.png` — the opposite (south-east) corner, same joint on the other axis.
- `whole.png` — pulled back far enough to see all four sides at once: one rail per side, one sign
  each, trees inside the fence but clear of every rail, no doubled panels anywhere along a run.
