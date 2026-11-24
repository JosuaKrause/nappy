# minty-quail — The pelican flag moves into the event surroundings, and the rigs build their own parts (A2b P) · 2026-11-24

The fourth of the pull requests of the design that makes the event manager's five parts
(`ahead`, `checkpoints`, `spawner`, `streaming`, `warnings`) internal: the readers in the pelican, builder,
run-config, loose-dog suites and in the finale, escape roadblock and basement rigs move to the answers
the design names. The five `[own file only]` lines stay until the pull request that renames them.

**Built.**
- `--pelican` is a setting of `EventSurroundings` (`rigging_the_pelican()`, `pelican_rig()`, `BAG` by
  default), like `--skip events`. `EventSpawner.rolls_a_pelican()` reads it off its world;
  `SimulationBuilder` rigs the surroundings it builds. `EventManager.rig_the_pelican()` and
  `EventSpawner.rig_the_pelican()` are gone: their one game caller was the builder.
- `test_pelican.gd` tests the bag through an `EventSpawner` of its own over a world of its own; a rig set
  mid-walk goes through the manager's surroundings. The builder and run-config suites ask
  `pelican_rig()`. The builder suite's full-bag count (one pelican in 400 rolls) was the bag's own
  behavior, `test_pelican.gd`'s, and is dropped as a duplicate.
- The roadblock rig's `Stage` owns an `EventStreaming` and an `EventSpawner` over its manager's world
  (the manager never ticks), and offers `event_of()` and `stream_out_and_in()`; `finale_rig.gd` asks the
  Stage. The finale's mark-over-her-head case starts a walk (`start_recipe()`), streams through
  `stream_around()` (one check added: the band is out of the world once she is away), and asks a
  `WarningBoard` of its own with the manager's tick off.
- `basement_walk_rig.gd` steps the manager with real physics ticks (`pass_ticks_faster`, delta `STEP`);
  `walk()` is awaited, and the parked probe `basement_meter.gd` awaits it.

**Measured.** One basement walk (`walk(0, 0, false)`, 5.3 s of game time) gives the same peak (3.8),
seconds and held list on both; it takes 15 ms hand-stepped and about 2.2 s on real ticks, so the parked
probe, which makes hundreds of walks, runs far longer than before and was not run to the end.

**Set aside.** Real ticks for the roadblock Stage (no player, nothing for a tick to do); keeping the
rig on the spawner (a hand-in only a test would use).
