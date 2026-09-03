# Playtest 22 — 2026-09-03

A screenshot from day 6 of a run on `main` at `db09693`, and the day-2 dusk map from the same run.
Two findings: barriers are still placed wrongly, and the city off the path is still bare.

Evidence, both copied into `docs/evidence/`:
`run-2026-09-03T205437-seed2102613802-db09693-060s-asked.png` (the day-6 screenshot) and
`run-2026-09-03T205437-seed2102613802-db09693-map-day02-dusk.png` (the dusk map).

---

## 1. Barriers still leave gaps and overlap other things

> "barriers are still placed in odd ways that leave gaps and overlap with other things."

**"Still" is right, and M48 is why it is only half fixed.** M48 gave a stationary pavement obstacle
two things: a position centred on the whole two-tile pavement band rather than on whichever of its
two lanes the scheduler picked, and a rotation taken from the street it stands on so a barrier lies
*across* the street rather than along the kerb. **Both of them are switched off on the same ground,
and it is the corners.**

- `EventInstance._spread_is_vertical` — which decides whether a barrier's segments are laid along
  local Y instead of local X — returns `false` whenever *both* of a tile's coordinates fall inside a
  corridor band. Its own comment names the case and calls the answer deliberate: a junction tile
  "belong[s] to two streets at once, with no single direction to be wrong about", so it "keep[s] the
  spread's long-standing lay along local X".
- `EventInstance._centred_on_the_pavement_band` gives up on exactly the same tiles, because it asks
  `CityMap.pavement_inward`, which returns `Vector2i.ZERO` when both coordinates are inside a
  corridor band. Its comment: "a junction belonging to both corridors at once — nothing here has one
  band to be centred on."

So a barrier on a corner keeps the raw lane-tile position the scheduler chose *and* the unrotated
east–west lay, whatever street it is meant to be blocking. **That is one pavement tile in six.** The
lattice repeats every `BLOCK_SIZE + STREET_WIDTH` = 14 tiles; a 14×14 cell holds 96 sidewalk tiles,
and 16 of them — the four 2×2 corners of the crossroads — are corner tiles.

**The screenshot is consistent with a corner placement, and that part is a reading rather than a
measurement.** The barrier in it is drawn 70 world px wide (the screenshot is a 2× letterbox of
640×360 of world), which identifies it as `construction`: `obstructs_radius` is
`SIDEWALK_SPREAD_MAX`, `SIDEWALK_WIDTH * TILE_SIZE * 0.5` = 32px, so it obstructs 64px — exactly the
pavement's width. It lies east–west with its right-hand end over the carriageway of a north–south
street, and its centre reads about half a tile off the pavement band's middle, which is the
signature of the un-centred lane position. **Nobody has confirmed the tile**, so the first thing the
fix owes is reproducing it: the seed is 2102613802 and it is day 6.

**And there is a second, smaller overlap that is certain and is not about corners.**
`EventInstance._draw_spread`'s docstring says a blocking object "is drawn at exactly the width it
obstructs… Anything else would be a lie about where the player can walk." It is not: the end caps
are drawn *centred* at ±`half`, so a 6px-wide `barrier_end.svg` post hangs 3px past each end. A
`construction` barrier obstructs 64px and draws 70. Three pixels either side is small, and it is
still the picture disagreeing with the collision by the rule the function states about itself.

## 2. Off the path is still empty, and that is because the fix is not built

> "did the previous session land? the off-path areas are still completely empty"

**It landed, and what landed was the measurement, not the fix.** The last session's two commits
(`4559e31`, `db09693`) refuted both causes playtest 21 proposed and measured the real one: a street
on the day's route carries **0.82 events** and a street off it carries **0.23**, one event every
four streets. The corridor is 29% of the lattice and holds 59% of everything standing on a street.
That measurement is in `docs/TODO.md` under M64.

**M64's own sealing — the thing that would fill the off-path city — has not been started.** Nothing
in `src/` seals a street: no seal picture exists, no placement pass, and the corridor policy is
still M50's gradient. So the dusk map showing bare ground off the violet tree is the game working
exactly as `db09693` measured it, not a fix that failed to take.

**What is left to build is both of M64's open items**, and their size is already written down: the
eight seal pictures, and placing them off the tree at about 187 segments a day (264 lattice streets
less the 76.6 the tree covers).

**What the last session did produce**, so the accounting is complete: two commits on `main` touching
`docs/TODO.md` and nothing else, and one unmerged branch — `feature/normal-density-on-the-path`, one
commit, one new file, the 256-line probe `tests/test_zz_m64_measure.gd` that produced the table
above. Not one line of `src/` changed. The session was spent measuring, and the measurement then
changed the design — it deleted M64's density item outright and replaced the sealing item's estimate
with a measured size — so the output was a re-specified milestone rather than a built one.

## 3. A run is a folder, and a repeated day is a new picture

> "also repeating a day should create a new image. also instead of encoding everything in the
> filename let's do folders instead"

> "so all files of a run stay together"

> "folder should be <day>/<commit>/<run>/<type> where type is automated screenshot vs maps vs
> manual screenshots log file lives directly in the run folder"

> "also no automatic cleanup anymore"

> "the folder structure allows for easily deleting old days/commits"

Changes to how the run log and its pictures are written, and they are one milestone —
[M70](TODO.md).

**The filename carries the whole run identity today**, and every artifact repeats it:
`Telemetry.begin_run` builds a stem of `run-<timestamp>-seed<N>-<commit>` and every file in the
directory is that stem plus a suffix — `.log`, `-060s-asked.png`, `-map-day02-dusk.png`. So a run's
files are scattered through one flat directory, sorted next to each other only by luck of the
timestamp sorting first.

**And a replayed day overwrites its own map.** `Telemetry.write_map` builds its path from the day
number and nothing else — `<stem>-map-day<NN>[-dusk].png` — so a day played a second time after a
nerve is spent writes over the first attempt's picture. The evidence of what went wrong the first
time is destroyed by the retry, which is exactly the run the map was worth having for.

## 6. The guidance works and it shows its working

> "can we reduce the density of the full barriers a tiny bit by doing a pass in the end that removes
> a small fraction of sidewalk barriers (only on non-paths and only on sidewalks *not* full street
> closures) — right now the guidance is there and properly pushes the player in the right direction
> but it feels a bit on guardrails so removing some obstacles randomly might lead the player down a
> bad path until they return to the actual path because they get stuck otherwise. this makes the
> actual path the player takes feel more organic, self-chosen, and earned. the goal is to guide the
> player without having the player know they are being guided. subtlety is key"

**This is a verdict on the sealing before it is a request.** *"The guidance is there and properly
pushes the player in the right direction"* — the milestone works. What is wrong is that it works
visibly: every street off the route is closed, so the open ones are a corridor with walls, and a
player who notices that is being routed rather than routing.

**It is also M45's recorded trap, sharpened.** That entry says *"a nudge that removes the decision is
worse than a closure that does nothing"*, and M64's own text answered it by leaving the route tree at
full width so a decision survives *inside* the open network. This says that is not enough: the
decision has to survive at the **edges** too, and the way to buy that is a wrong turn that stays open
long enough to be taken.

**A wrong turn is the point, not a side effect.** *"Removing some obstacles randomly might lead the
player down a bad path until they return to the actual path because they get stuck otherwise."* So
the fraction removed is not a softening of the walls — it is what makes the walls discoverable by
walking into them, which is the only way a route can be *earned* rather than followed.

**It collides with a standing rule and the collision is only apparent.** `CLAUDE.md` lists, under
things deliberately not done: *"Closures and events are checked before they are accepted, never
repaired afterwards. If you find yourself writing a pass that deletes what a previous pass placed,
this is the rule you are about to rediscover."* This asks for exactly such a pass. **The rule bites
where a later pass can invalidate what an earlier one guaranteed**, and removal cannot: every
guarantee the sealing carries is about *reaching* somewhere, and taking a barrier away can only make
more ground reachable. A thinning pass is monotone in the safe direction, which is what makes it the
exception rather than the rediscovery.

## 5. The doorstep can be sealed in, and the sealing's guarantee cannot see it

> "the starting area was sealed off completely and the only way out was alongside the main road
> which basically ends the day"

**One segment is exempt from sealing and it is not enough.** `SealPlanner.plan_day` skips exactly
`ClosurePlanner.home_street(map)` — the one street segment containing the doorstep — for the stated
reason that *"the home is a notch with one exit, so sealing it seals her in"*. Every street that
home street *leads to* is fair game.

**And `RouteTree` colours no home node**, on the principle that *"a door is not a route"*. So the
day's tree begins somewhere out in the lattice and the home street is exempt, and **nothing protects
the join between them.** If every street at the far end of the home street is off the tree, all of
them are sealed, and she is walled in on the first frame with the main road as the only way out.

**This makes `SealPlanner`'s own winnability claim false as written.** Its docstring says the
guarantee *"is not re-proved here, it is true by construction — a seal never stands on tree ground or
on the home street, the two things `RouteTree`/`ClosurePlanner` already guarantee a route through, so
nothing here can cut the corridor."* Those are two guarantees about two disconnected things. Neither
of them, nor both together, guarantees a walkable line from the doorstep to the corridor.

**`tests/test_seals.gd` passes and is measuring the wrong thing.** It asserts over 6 seeds × 14 days
that *a calm area is still reachable* with every seal and closure standing. Reachable is not the
question this run asks: she could reach one, along the spine — the ground whose excitement decay
multiplier is **0.6** against an ordinary street's 1.0 — and that is what *"basically ends the day"*
means. **Reachable is not survivable**, and the test has to be stated over a route the day can
actually be won on.

## 4. A route may cross the main road and never run along it

> "also, a path should never go alongside the main road — main road by itself can be considered a
> blocker — paths can only cross the main road"

**`RouteTree` knows nothing about the main road today.** It grows on `ReachabilityGrid` cells and
asks only whether ground is walkable, so a strand can and does run straight down the spine. Nothing
in `src/routes/` mentions `main_road` or `street_kind`.

**The half that is unambiguous and has no collision: a strand may not run along it.** The main road
is already the worst ground in the game to stand on — it multiplies excitement decay by 0.6 against
an ordinary street's 1.0, calm's 2.2 and a precinct's 1.5 — so a route that uses it as a corridor is
a route the day planned onto the one surface designed to punish standing still. Making it *not a
route* rather than *a dear one* is the same move M64 made everywhere else.

**The half that needs an answer is what *"a blocker by itself"* means**, because two readings differ
in a way that matters and only one of them is safe:

- **It is already a wall, so do not seal it.** M64 seals every street off the day's tree, and the
  main road will now never be on the tree — so the rule as written would put a seal on every segment
  of the spine. This reading says do not: the road is barrier enough, and crossing it stays exactly
  as free as it is today, at any light or zebra.
- **It blocks, so she crosses only where the tree crosses.** This reading makes the spine a wall with
  doors cut where the day's routes meet it, which is M62's checkpoint geometry arriving early.

**The run that produced this reading settles it.** *(2026-09-03, on a dusk map of a run with the
sealing in: "look at this run — the starting area was sealed off completely and the only way out was
alongside the main road which basically ends the day".)* The home sits one block off the spine, the
streets around it are sealed, and the only unsealed way out is the main road. So the reading is the
first one: **being forced onto the main road is the harm**, and sealing the spine would make it
worse rather than better.

**The second collides with a recorded decision and the first does not.** `docs/CITY.md` says the
main road is the run's arc *"emergent by construction, and nothing enforces it"* — *"She is never
**held** on one side and never steered at the road — she may cross whenever she wants, and crossing
on day 1 is playing correctly rather than early"* — and then, as a constraint on what may be built:
*"Nothing may be added that withholds the far side, gates it behind a day number, or nudges her
toward a crossing."* A spine crossable only where today's tree crosses it is exactly a nudge toward
a crossing.

**The hierarchy is the cleanup.** *"No automatic cleanup any more"* removes the 50-log cap the game
enforces on itself today, and the reason given is the structure: a tree of date, then commit, then
run is one somebody can delete a whole day or a whole commit out of. So the directory grows without
bound on purpose and emptying it is the player's to do, rather than the game's to do behind them.
