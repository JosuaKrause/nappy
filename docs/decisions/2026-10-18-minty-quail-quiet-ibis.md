# minty-quail — The city's own parts take what they read (minty-quail, the hand-ins) · 2026-11-10

**The ask.** A component is handed what it depends on (minty-lemur #794), and "never read fields
directly. always read through a method" (inbox #1173 in gray-dolphin). The third hand-ins pull
request of `docs/todo/2026-10-18-minty-quail/city-hand-ins.md` lists smaller cases that are handed
the whole `City` and read a few things off it; a Fable planning agent cut that pull request smaller,
and this is the city's own parts.

## What was built

- **`SceneryResidency.setup(world, map, ground, shadows, decals)`**: handed the node whose visibility
  and viewport it follows (the city), the map, the scenery's ground, the building shadows and the
  decals, in place of the city; its two reads of the city's underscore members are gone.
- **`SceneryGround.configure(map, source_of, composed)`**: handed the map and a callable for each
  tile's ground source (`City.scenery_ground_source`), in place of the city.
- **`Blackout.setup(map, buildings, signals, events, resistance)`**: handed what it reads, the
  resistance being the run's, whose sabotage it watches.
- **`PosterWalls.setup(buildings, map, run)` and `watch_events(events)`**, the second called by
  `City.build()` right after the events are made, since they are made after the walls.
- `City.build()` hands each its parts; `tests/test_blackout.gd` builds no `City` and hands the parts
  with a fake event manager. `tools/field_reads.txt` lost twelve lines and gained none.

## Two members kept public for the suites, open to the player's overturn

`tools/test_only_members.txt` gains `City.scenery_ground` and `City.scenery_ground_source` in its
`[kept]` group: once the parts are handed them, only suites and probes read them outside
`city.gd` (`scenery_ground` in six suites and five probes; `scenery_ground_source` is also called by
`SceneryGround` through a callable the check cannot follow). The residency suite's own reads go
with the scenery suites' conversion (`tests-one-module.md`, entry 3); `City.scenery_ground` stays
for the five other suites and the five probes that read the ground off a real city, and
`City.scenery_ground_source` stays because the game reads it where the check cannot see. The
builder's choice, which the orchestrator kept; the plainer alternative is both made internal and
their suites and probes rewritten.

## Parity

The run log is line for line what it was (`tools/test.sh observers`), and what every source charges
her is the same on `main` at `651606332` and the head (`probes/excitement_fingerprint.gd`, its `XF`
lines less `XF_COST`), and so is every event, crowd agent and meter on every tick
(`probes/m159_tick_sweep_events_cost.gd`, its 72 `chain` values, run whole on both trees by the
review, after the builder's two runs were cut short on a loaded machine). The review's whole runs,
one at a time on each tree: the 72 `chain` values hash to
`bf69e949b75fb076edc5d987237f0258569e0231800c0507d450f768307dd2d2` on both and are equal line for
line, and the fingerprint's 19758 `XF` lines hash to
`7510c1d0bf9b374a3efad318de294cf2751ba8288dfcc9cfd456325b9062d625` on both.
