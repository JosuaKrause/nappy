# minty-quail — The dev flags are resolved once at boot into one run configuration, handed to what needs it · 2026-10-19


minty-quail's `run-config.md`, the refactor's second PR (PR #807). The item: `DevFlags.invincible()`
ran every frame and, on the published web build, evaluated `window.location.search` through
`JavaScriptBridge` at least twice a frame; the shipped day length came from a dev class
(`DevRig.day_length()`) and was resolved three ways; about 45 `_recipe` branches ran through main's
shipped flow; simulation, `CityMap` and the observers read `DevFlags` directly; the rig flag list
existed twice, main's copy missing `--tap`.

**Built.** `RunConfig` (`src/run_config.gd`) holds every flag value, the release and debug gates, the
page's query and the `--no-telemetry` opt-out. `RunConfig.at_boot()` reads it once per process, the
only place the game reads the address bar; tests build one with `RunConfig.parse(words, query,
debug_build, ...)`. A built config refuses every later write with a warning, its lists are read-only, and every read of
the gated words is a copy. It decides a day's length (`day_length_for()`, `escape_section_length()`),
replacing `DevRig.day_length()` and `FinaleController.length()`. `DevFlags` is only the parser now,
built from what it is handed; the blocks the shell tools read (`DEV_FLAG_TABLE`, `RIG_FLAGS`,
`RIG_QUIT_SECONDS`) are byte-identical, and the static seams `_invincible_override`,
`args_for_tests` and `recipe_data` are gone. `main` hands the config to `Telemetry`, `GameSave` and
`VisitCounter` through `configure()`, and plain values to simulation: `DayController.invincible`,
`Baby.excitement_frozen`, `FinaleController.invincible` and `section_length`, the day's length, and
the city's values set before `build()` and passed on to ground, scenery, shadows, events, the crowd
and its agents, blackout, the pelican drawing and `--force`; the run-log observer gets `--spikes` on the day and in the escape alike, as a setup
parameter; the building's events get
`skip_drawing`. `CityMap` lost `recipe_frame_locked`. One rig flag list, read as `config.is_rig`. A
recipe's seed, day, escape part and parent come in through `config.with_recipe()`; the frame lock,
the shader warm-up skip and the title skip are config values; main's write of the recipe runtime's
private `_active` is the runtime's own `lose_the_attempt()`. No test sets a `DevFlags` static; the
runner's per-suite reset clears the three observers' configs, where step 1a's record has it clearing
the `DevFlags` seams. `tests/test_run_config.gd` covers the gates, immutability, the recipe overlay,
the lengths, every rig flag, the title skip, and the values reaching the baby, the city's parts and
the escape clock.

**Verified** by `check.sh`, `lint.sh`, `tools/test_cli_help.sh` and every suite the change touches, 0
failures; three `--no-save` stills (a day with `--invincible`, `--start-escape`, `--start-escape city
--day-length 40`) show nothing visible changed. The full suite is CI's.

**Choices made where the design was silent, open to overturn:** each setter refuses a write after the
build with `push_warning` rather than `push_error`, since an engine error line fails the test run that
meets it and a test could not then exercise the refusal; a recipe is kept only on a debug build, so a
release parse handed one answers none of its values; `at_boot()` is kept per process in a static, so a scene reload is not a second boot; `DevFlags`
stays apart from `RunConfig` because the shell tools read the flag table from its file; before a
config is handed in, `GameSave` uses no save, `VisitCounter` sends nothing and `Telemetry` behaves as
for a run with no flags; the city's values are plain fields, not a settings object; `--pelican` maps
onto `PelicanRig.ALWAYS`; the HUD's debug view keeps the build's own answer until the config arrives;
the escape's flag boot takes its day only from a recipe, as before; a recipe's screenshot moment
reads `--after` as a number, which differs only for a malformed value such as `2s`.

**The item's "day length is a day-spec value"** is not built here, since no day spec exists yet:
`RunConfig.day_length_for()` resolves the length in one place and hands it in as a plain value, and
`escape-as-day-spec.md`'s `DaySpec`, which already lists the length among its fields, takes it over.

**Left to `main-and-state.md`**, written into that item: the `_recipe` branches that need `RunFlow`,
and the two flags (`--touch` in `TouchInput`, `--web` in `QuitOption`) that still read the command
line themselves. `comments.md` was applied to the passages edited and to all of `dev_flags.gd`, not
to whole large files.
