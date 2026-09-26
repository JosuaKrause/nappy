## M183 — The power station and the blackout, slice one: the power station · built 2026-09-23

*([PLAYTEST-119](../playtests/PLAYTEST-119.md), [PLAYTEST-121](../playtests/PLAYTEST-121.md); the
player on 2026-09-23, on the first stills: "maybe for the full picture zoom out from the regular
view instead of zooming in from the overview", "also, yes, go ahead and let opus try", and on the
redraw: "power station looks good".)* One Opus agent on `feature/power-station`, reviewed here;
the blackout and the dark escape stay open in `TODO.md`.

**What was built.** Exactly one big building is the power station on every seed: the roll of
`Tuning.MIN_BIG_BUILDINGS`..`MAX_BIG_BUILDINGS` now counts it, the ordinary landmarks are placed
first and the station last (`CityGenerator._place_power_station`). A candidate is accepted only if
it is two blocks wide, passes every landmark rule, has its door on the real street south of one
of its blocks, stands at least `Tuning.POWER_STATION_MIN_BLOCKS_FROM_HOME` (4) blocks from the home
block in lattice distance, and its door's street ground is not in the home's region; if nothing
qualifies, `validate()` fails and the next seed is rolled. `CityMap` answers `power_station`,
`power_station_door`, `power_station_door_street()` and `power_station_door_position()`. **On day
14 the route tree grows a spur** from the door to the nearest cell on the tree, after the
branches and the trunk and with no dice, so the rest of that day's corridor is unchanged; the
existing rules then make any boundary it crosses a door and keep seals and closures off it, and
`ClosurePlanner._invariant_holds` also refuses a closure that would cut the door off on that day.
**The look**: a steel-clad hall with tall unlit clerestory windows, a heavy riveted service door
with hazard-striped guard posts and a high-voltage plate, a hazard band along the base and two
striped stacks, beside a fenced yard with three transformers (`art/buildings/power_station_*.svg`,
`Building._draw_station_facade`, never act-tinted). **`--spawn power_station`** stands her at the
door, and **`--zoom <factor>`** scales the day's camera for a whole-building picture.

**Measured.** Door distance from the home block over 200 seeds: 4 blocks 63, 5 62, 6 42, 7 31, 8
2. Industrial blocks under the station: both 2, one 100, none 98. Day 14's door reachable on 40
of 40 seeds with the spur, 25 of 40 without. 187 of 200 existing seeds generate a different
city; none needed to roll on; generation is about 5% slower. A save holds only the seed, so an
old save loads into the new city, and `CityState.purpose_of` reads an arc stage past a block's
end as its last step, so a save whose block became the station loads
(`tests/test_power_station.gd`).

**Tried and rejected.** *The first street front*, ordinary wall tiles and lit windows with a
steel door, read as an apartment block from the door · redrawn on the player's word. *A 4x crop
of the overview as the whole-building picture* · replaced by the ordinary view zoomed out, the
player's instruction. *Doors off the tree to keep the station reachable* · not taken: it would
break M62's rule that a crossing is a door only where the day's tree uses it; the spur is smaller.

**Open to overturn, chosen where the design was silent.** The station is placed last and each
candidate is built and the regions grown on the result, restored exactly if the door lands in
the home's region. "The station's region" is its door's street ground. The reachability refusal
is day 14 only. Candidates rank both blocks industrial, then one, then nearest industrial
ground, which leaves the industrial preference met in full on 1% of seeds, since industrial
blocks are scattered singly. Horizontal pairs only, since only the south face is drawn; the door
goes on the block nearer home, then west. The hall and the yard are two halves of the mass.

**The decision, as the queue held it when this was built:**

- [ ] **Every city has a power station.** One big building — the landmark `docs/CITY.md`
      describes, two neighboring blocks and the street between them built as one mass — is the
      power station on every seed, with a look of its own (stacks, a fenced transformer yard)
      and a front door on a street she can reach on day 14. Today the generator asks for
      `Tuning.MIN_BIG_BUILDINGS` to `MAX_BIG_BUILDINGS` of them and places as many as its
      candidates allow, so a seed can end with none; the guarantee is checked when the
      footprint is accepted, never repaired afterwards. What it does to existing seeds and
      saves is measured and said. Which district it stands in is the orchestrator's and open
      to overturn: industrial. **It is not in the home's district**, decided by the player on
      2026-09-21, since day 9's task in M181, the resistance has a reason, and a task is one
      day, is for a station that is across a door; day 14 crosses one, and the guarantee that the front door can be reached on day 14
      is checked with the doors and that day's closures in place.
      **It is a reasonable distance from the home, and reaching it takes a door crossing**
      ([PLAYTEST-121](../playtests/PLAYTEST-121.md): "the route does not need to go past it from
      day one. the narrative demands a gate crossing for reaching it"). It is in the city from
      day 1 like every building, and nothing leads her to it before day 14.
