priority: later

# azure-egret — SpawnSiting.least_distance() is a second name for Offscreen.min_boundary() · filed 2026-11-23

**What is wrong.** Since pull request 1664, `SpawnSiting.least_distance()` (`src/world/spawn_siting.gd`) is
`return Offscreen.min_boundary()`: the view's half height, 180px, under two names, which is a place for the two
to drift apart. polite-tapir's standing-rest design, section 2, sends removing it to the queue; this is that
entry. A filing from a review, not from the player's words; the band, `later`, is the filer's proposal.

**What a builder does.** Delete `least_distance()` and read `Offscreen.min_boundary()` where it is read, which is
about ten files: `src/world/spawn_siting.gd` itself, `src/events/event_spawner.gd`, comments in
`src/offscreen.gd` and `src/events/data/event_catalogue.gd`, `tools/cost_table.gd` (which writes a sentence of
`docs/COSTS.md`), `docs/EVENTS.md`, `docs/COSTS.md`, and the suites and probe `tests/test_spawn_siting.gd`,
`tests/test_events_pursuit.gd`, `tests/test_pursuer_on_foot.gd`, `tests/test_resistance_placement_kinds.gd` and
`tests/probes/m174_pass.gd`. The list is `rg -n 'least_distance' -g '*.gd' -g '*.md' .`, run again.

**Shown fixed.** The same search finds nothing; `tools/cost-table.sh --check` and the suites that named it pass
with unchanged check counts.
