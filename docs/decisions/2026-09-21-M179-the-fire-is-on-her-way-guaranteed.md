## M179 — The fire is on her way, guaranteed · built 2026-09-21

*(2026-09-20, [PLAYTEST-117](../playtests/PLAYTEST-117.md): "I have never seen a fire truck. I
mentioned a couple of times that the fire should come first and be on your way *guaranteed* (a
dynamic event dependent on the route you chose that day) then the fire truck should come and
player better get away from the fire."; [PLAYTEST-119](../playtests/PLAYTEST-119.md), statements 21
to 27; [PLAYTEST-120](../playtests/PLAYTEST-120.md); [PLAYTEST-121](../playtests/PLAYTEST-121.md),
statements 4 and 5.)* Two agents on `feature/fire-on-her-way`, the second replacing the first
after the player paused the build to correct it; reviewed here twice.

**What happens.** `burning_building` carries `EventDef.sited_on_her_way`: the day budgets it,
decides its role and what ground it may take, and leaves only *which* tile to her walk.
`EventScheduler.WalkSiting` sites it on an `AGAINST_THE_BUILDING` face on the branch of the day's
`RouteTree` she is standing on, ahead of her along the route, beyond the streaming band; off the
tree it waits. It moves while it has not entered the world — behind her, or on a branch she left,
for three seconds of walking — on the way out and on the way home alike, and is fixed the moment
it streams in, which is where its scar and its block's arc are recorded. The engine comes on first
sight and **parks** across from it for the rest of the day (`EventDef.stops_where_it_arrives`). A
site is accepted only where, from where she stands, the home and a calm area she has not used stay
reachable with both fields treated as closed ground. A lost day 3 gives back
`consumed_one_shots`, `scars` and `CityState` with the resistance's fields, so the retry is the
same day from the same state and owes a fire again. A day 3 she wins with the fire never in the
world lights it at the end of the day (`EventManager.light_what_she_never_met()`), away from where
she finished, so the shell stands on day 4.

**Measured** (`tools/test.sh probes/m179_fire_on_her_way.gd`, four rigs on three seeds: out and
back down a real route, turning back at the first junction, a straight line through the lattice,
staying near home). Sited 18.0 to 28.3s in, 1261 to 1864px ahead; first seen 32.7 to 43.0s later;
the beat lands 53.7 to 62.8s into a 180s day; six of six route walks met it. Passing the pair
costs 197 to 223 on a meter that ends the day at 100; the detour is 792 to 1176px, 8.6 to 12.8s.
No siting was refused for closing her way out in twelve walks. A refused attempt costs 2.0ms
mean, 20.2ms worst, once a second. Three of twelve walks ended with the fire never in the world,
all of them the near-home rig, and all three were lit at the end of the day, 1338 to 2241px from
where she finished.

**Tried and rejected.**
- *Within 180px of her straight-line heading* (the first build's `ON_HER_WAY_DRIFT`) · refused by
  the player: "valid spawn locations are only on the path". Under it the first sight came 9.5 to
  16.0s after siting; on a route it is two to three times that, because a route winds and the
  near end of the band is the streaming radius. That is the one cost of siting on the path.
- *The engine passes through*, as it had since M101, the fire is found before the engine, and
  *parks for about twenty seconds* · the player chose the rest of the day: "a fire engine has a
  high cost", "you're not supposed to go past it".
- *Stop siting once the return leg starts* · refused by the player: "if they managed to avoid it
  thus far they should still have to try avoid it further".
- *A fire that burned stays spent on a lost day*, the first build's reading of `finish_day()` ·
  overturned by the player: "nothing that happened on the day that got retried can influence the
  next repeat". `GameState.begin_day()` runs before `CityState.begin_day()`, so the photograph
  precedes the dawn arc roll and the retry makes that roll again, identically.
- *A fake `spawns_on_finish` to make the engine stop* · not taken; the flag says what it means.
- *Widening `last_day` so day 4 owes an unmet fire*, and *accepting a run with no fire* · the
  player agreed to the fire at the end of the day, which keeps the scar unconditional and moves
  no act's beat.

**Open to overturn, chosen by the agents where the design was silent.** Sited after 18s of
walking and 400px from the doorstep. The band's far end is measured along the route and its near
end across the block. Widening is stepped: twice the band, then the whole branch. Re-siting also
fires when the placement is on a branch she has left. The question is asked once a second. Which
way a route goes is read over eight cells. The fire is exempt from the sidewalk-line guarantees,
since closing that sidewalk is the point. The end-of-day fire is past the streaming band from
where she finished, off the routes' ground where it can be, and rolls its own stream. **The fire
can come into view with the outer edge of its field already on her**: the view is 180px deep up
and down the screen against a 260px field, so the tests hold the telegraph contract's own worst
case — outside the inner radius, and clear of the field within the 2.2s telegraph — rather than
"outside the field at first sight". The parked engine has a field and no body. What a person has
to judge is in `docs/REVIEW.md`. No picture of the parked engine exists: a `--walk` script holds a
compass heading and the fire is met by walking a route.
