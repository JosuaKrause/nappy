# Dev flags resolved once at boot into an injected run configuration

- `DevFlags.invincible()` runs every frame (`src/day/day_controller.gd` near 79 and 89,
  `src/player/baby.gd` near 143); on the published web build it reaches `_web_query()`, which runs
  `JavaScriptBridge.eval("window.location.search")` (`src/dev/dev_flags.gd` near 316): at least two
  JavaScript evaluations per frame on a phone.
- The shipped day length comes from a dev class, `DevRig.day_length()` (`src/main.gd` near 1951,
  1994, 2006, 2045; `_dev_rig` is always built, near 262), and is resolved three ways (`Tuning`,
  `DevRig`, `FinaleController` with `DevFlags.day_length_override`).
- About 45 `_recipe` branches run through main's shipped flow (the escape handover near 2361, the
  summary's continue near 2372, the section start near 1029-1038 writing the private
  `_recipe._active`); the static `DevFlags.recipe_data` is checked before the `enabled()` gate in
  `seed_override()` and `start_escape()`; the rig flag list exists twice (`main.gd` near 2775,
  missing `--tap`, and `dev_flags.gd` `_RIG_FLAGS`).
- Simulation reads `DevFlags` directly (`crowd.gd`, `crowd_agent.gd`, `event_instance.gd`,
  `building_shadows.gd`, `scenery_ground.gd`, `finale_controller.gd`); `CityMap` carries a dev field
  (`recipe_frame_locked`); `Telemetry`, `GameSave` and `VisitCounter` read `DevFlags`.

**Build:** one immutable `RunConfig` resolved once at boot from the command line and the page's
query, injected where it is needed; simulation receives plain values (`clock_frozen`, `day_length`)
instead of asking `DevFlags`; day length is a day-spec value; scene recipes are configurations of the
day path, not branches in it; one rig flag list.
