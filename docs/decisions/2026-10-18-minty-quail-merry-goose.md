# minty-quail — Run flow, save and pause: each suite says why it is combined · 2026-11-08

minty-quail's `tests-one-module.md`, entry 9, in #1247, a commit per suite. The entry's suites boot
the real run and are combined by composition; each now states its reason in its header, and every
boot and build takes its city from `tests/city_map_cache.gd`.

**Per suite** (local times before and after, one run each, load varying; no check changed):
- **Combined, each with its reason:** `run_flow` (where a screen's continue leads shows only in the
  real `main`; 5.6 to 4.9 s), `run_config` (handing values to `main` and to a built city is
  composition; 14.4 to 13.4 s), `run_checkpoints` (the booted cases hold what a checkpoint means in
  the booted world; 19.8 to 17.8 s), `save_wiring` (what `main` does with the save; 24.8 to 24.2 s),
  `boot_handing` (the hand-over of the player and the controls' cover is `main`'s; 4.2 to 4.0 s),
  `observers` (which notes the observers are handed across a scripted run; 8.2 to 8.0 s), `main`
  (the composition root; 24.5 to 23.7 s), `dev_rig` (the `--spawn` targets are promises about a real
  placed day; 3.5 to 3.2 s), `park_return` (the softlock chain spans modules; 37.6 to 35.9 s).
- **Its own module:** `save` (`GameSave` on scratch files; its fence round trip's map from the
  cache), `pause` (unchanged: it boots nothing), `day_loop` (one module but for the booted summary
  and the retry case; 2.3 to 1.6 s).

**Choices where the design was silent, open to overturn:** the entry's "combined by composition,
each with its reason stated" is read as keeping these suites combined with the reason added, not
splitting `main`'s boot module by module; `save_wiring`'s unseeded boots still generate their own
city, since caching a random seed only fills the cache; `Boot.boot()` keeps defaulting to no cache,
each suite handing `MapCache.source()` as `test_main` already did.

**Left:** three checks belong to other modules; the item's order names them.
