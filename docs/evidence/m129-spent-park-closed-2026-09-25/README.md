# M129 — a spent park is closed

Two stills of a calm area she has already used this act, shut the way `ClosurePlanner.calm_to_shut()`
shuts one: `ParkClosure` stands the same barrier panels and `closed` sign a street closure's mouths
get, along every entrance to the area's own ground. See `docs/CITY.md`, "Shutting a spent park".

## Why these are not a `tools/shot.sh` capture

Every dev-flag boot (`--day N` included) starts from an empty `GameState.settled_in`, because
`--day N` skips straight to that day rather than actually playing the days before it — so nothing is
ever "already used" on a fresh boot, whatever day it names. Reaching the state naturally means
actually playing a day to the point the baby falls asleep on calm ground and walking home to bank it
(`GameState.finish_day()` only keeps a day's `settled_in` entry on a win), and `--route calm,home`
(`RouteRig`) quits the process the moment that day ends rather than carrying on into the next one —
so no single windowed session reaches "day 2, with day 1's park already spent" through the existing
dev flags, and `src/dev/` is fenced off to this PR (a live agent, M204, owns it).

So these are a small one-off script, not committed, that builds the same real `City` the way
`tests/test_spent_park.gd`'s own scene test does — `CityGenerator.generate()`, `City.build()` — and
hands it two calm areas as "already used" the same way `Main._start_day()` does:
`CityMap.set_spent_calm()` before `City.start_day()`. Everything downstream of that call is the
real game's own code: `ClosurePlanner.calm_to_shut()` decides what shuts, `City.start_day()` repaints
and draws it, and a plain `Camera2D` (the same zoom `Main._new_boot_camera()` uses, positioned the
way `--spawn closure:0` aims at a street closure's barrier) is all that stands in for the player.

Seed 14040, day 5, the two calm areas nearest the top of that day's `calm_blocks` handed over as
used; both were shut (`ClosurePlanner.calm_to_shut()` refused neither).

## The stills

- `entrance.png` — standing on the pavement outside one fenced edge, the barrier and its `closed`
  sign square in front of her the way a street closure's would be, the calm ground and its trees
  visible behind the tape.
- `corner.png` — pulled back from a corner of the same area, showing two whole fence lines meeting:
  every entrance on both sides covered, the corner overlap leaving no gap, and the shut ground still
  reading as park behind the fence rather than as something else.
