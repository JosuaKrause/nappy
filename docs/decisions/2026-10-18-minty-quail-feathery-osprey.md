# minty-quail — The city's map is asked: City.map is private behind map() · 2026-11-24

C5 of the city scene's pass (`.claude/briefs/designs/minty-quail-city-scene-pass.md`): the map
`City.build()` was handed is `_map`, asked through `City.map()`, named as `navigator()`,
`streets()` and `fronts()` are.

## What was built

- `city.gd` holds `_map` and answers `map()`; its own uses follow.
- Every use of `City.map` outside the file (1,122 uses on 1,041 lines in 100 files: `main.gd`'s
  20 lines, the suites, rigs, fixtures and probes) asks `map()`. The list of uses came from the
  engine: `City.map` renamed private in a scratch copy of main, every script under `src/`,
  `tests/` and `tools/` loaded, each use the parser refused listed as `file:line:index`.
- `tools/field_reads.txt` loses its last line, `src/main.gd map` under `[City]`, and so its
  group: the list is empty, and the check finds no read of another class's field under `src/`.
  The entry `field-reads.md` (convert every cross-object read to a method, type every receiver) is
  finished and its item file is deleted. What holds after it is `tools/check_field_reads.py` run
  against the empty list, which fails any new read; the reads it cannot see are the blind spots its
  `--help` states (a receiver typed too wide, a name read off a Variant in a file that opts out).

## Where the engine's list was short

- Two uses the parse did not report (`test_scene_recipe_runtime.gd` line 195 and
  `probes/minty_quail_crowd_frames.gd` lines 41 and 45; the probe does not parse for an
  unrelated reason, a variable declared twice) were found by search and changed by hand.
- Two uses sit in the `PROBE` script `test_scene_recipe_activity.gd` writes and boots; they are a
  string to the parser and were changed by hand.
- The scene recipe files hold no use of a `City`'s map: they ask `world.city_map()`, and their
  `.map` tokens are a Dictionary's key.

## Measured

A rename of a field that fails to parse when a use is missed owes no mutation. The 48 touched
suites, run in groups of five, report 0 failures; every scene recipe passes
(`tools/scene-recipes.sh`); `tools/check.sh`, `check_field_reads.py`,
`check_test_only_members.py`, `check_layers.py` and `lint.sh` pass.
