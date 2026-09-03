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

**The hierarchy is the cleanup.** *"No automatic cleanup any more"* removes the 50-log cap the game
enforces on itself today, and the reason given is the structure: a tree of date, then commit, then
run is one somebody can delete a whole day or a whole commit out of. So the directory grows without
bound on purpose and emptying it is the player's to do, rather than the game's to do behind them.
