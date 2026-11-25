# minty-quail — GameDawn takes its spec, rng and map in _init · 2026-11-23

**What.** The shared test helper `tests/game_dawn.gd` built its dawn by writing the new dawn's
private fields (`_spec`, `_rng`, `_map`) from a static `of()`, which the first counting
command in `tests-public-seams.md` listed as a breach. `GameDawn` now takes the three in
`_init(spec, rng, map)`.

**Kept: `GameDawn.of()`.** It stays as a one-line static calling `GameDawn.new(spec, rng, map)`.
About sixty call sites in a dozen suites and probes read `GameDawn.of(spec, rng, map).masts(...)`
as "the dawn of this day", and replacing each with `new` would touch every one of them for no
change in what any reads. A caller may use either.

**Measured.** The twelve suites that use `GameDawn` (resistance_traps, tutorial_dog,
events_placement, events_scheduler, scheduler_mouse_piles, return_patrols, telemetry,
event_spacing, resistance_alley_siting, spent_park, checkpoints, seals) pass 185155 checks with 0
failures on main and on the branch; the counting command no longer prints `tests/game_dawn.gd`.

