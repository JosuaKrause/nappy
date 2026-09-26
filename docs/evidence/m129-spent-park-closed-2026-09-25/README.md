# M129 — a spent park is closed

Superseded once already: the first pictures here showed every used calm area fenced off, which the
player turned down (`docs/playtests/PLAYTEST-140.md`, "Then, on the first pictures of a spent park"):

> "a park that was used should be shut down, yes, but by placing events in it how it was before.
> where does this barrier thing come from? doing it for one park, sure, more towards the later
> stages of the game once but not for regular" · "yes, the corners look wrong, too"

The design is now: **every** used calm area is spoiled with events, the way it always was, and the
day's route tree plans around it — no barrier, ground stays walkable. **One** area, at most once a
run and never before act III, gets `ParkClosure`'s fence instead. The stills are of that one fenced
park.

## The corners

The player on the second attempt's corners: "The corners of the park barrier are not fixed. Now
they're just disconnected. Do a proper fix." The west and east runs stopped one tile short of each
corner, so their end-on column ended about 30px below the north rails and never touched them, and
the north and south rails ran half a barrier's depth past the side lines. Now the fence turns each
corner as one fence:

- Every side's run covers its own corner tiles, and where two sides' runs share a corner tile both
  lines stop exactly at the corner of the two fence lines (`ParkClosure.fence()`), so neither stops
  short of the other nor runs past it.
- One post stands at that corner, a new picture, `art/closures/barrier_post.svg`: steel grey like
  the panels' own posts but as wide as the end-on column's two rails, capped, on a foot plate. The
  north and south rails end behind its middle.
- The west and east columns are drawn at the broadside rails' height (`ParkClosure.RAIL_RISE`, the
  lower rail's 7.4px), so a column leaves the north corner post right under the north rails and runs
  in behind the south rails and post. Its feet and its collision stay on the ground.
- An end-on panel stands its feet at the near end of its share, so the column covers its own ground
  rather than standing half a panel up the screen from it.

## The draft pieces, for review before they go in

The player on the corners above: "the closed off park is still bad. you probably need new textures
for corners." The front-view rails, the end-on bar and the grey post are three different objects
butted together. `fence-draft/` holds new pictures, not yet used by the game, that draw the fence as
one object: the same two rails, the same thickness, stripe and outline as `barrier_across.svg`, bend
90° at each corner (`corner_{nw,ne,sw,se}.svg`) and run down the west and east sides seen from
their end (`side_{w,e}.svg`), with the posts standing between them; a run that turns no corner ends
with the rails stopped square and its own post (`end_{n,s}_{w,e}.svg`). There is no separate corner
post. The north and south runs are the existing `barrier_across.svg` panels, unchanged.

The `draft-*` stills stand those pictures on the real city at the stroller's play zoom (2), with the
game's own park fence hidden: `draft-corners-{1x,3x}` (NW, NE / SW, SE, crops as above),
`draft-corners-closeup` (each bend enlarged), `draft-sides-{1x,3x}` (the middle of the north and
south runs / the west and east runs), `draft-whole`, and `draft-archway-{1x,3x}` and
`draft-archway-nosign-3x` (the one-tile archway of the courtyard at block (9, 8), with and without
its `closed` sign).

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

Seed 14040, day 9, camera at the stroller's own play zoom (2). In the two corner sheets the cells
are the NW and NE corners over the SW and SE ones, each a 320x240 crop centred on the area's own
corner; the 3x sheet is the same pixels enlarged with nearest-neighbour.

- `attempt3-corners-1x.png`, `attempt3-corners-3x.png` — the four corners as they are drawn now.
- `attempt3-whole.png` — the whole fenced park at play zoom.
- `before-corners-1x.png`, `before-corners-3x.png` — the same four crops of the second attempt, the
  one the player turned down, for comparison.
