# minty-quail — Four city suites hand each city a fresh run and read what the scenery draws (tests through public seams) · 2026-11-02

minty-quail's `tests-public-seams.md` and `run-state-handed-in.md`: four of the city and scenery
suites, partly. The brief named twenty-two; the other eighteen are untouched but for a rename, and
the item lists them.

**Built.**
- `City._ground` became `City.scenery_ground`, read across classes by `SceneryResidency.update()`
  before and now by name; the suites and probes that reached `_ground` read the new name. *Open to
  overturn:* a rename of a private another game class already read, which is a seam under the
  item's Build line but close to the rejected rename-for-a-test shape.
- `test_scenery_residency.gd` (private reads 74 to 12, hand-called frames 3 to 0) lets real process
  frames pass in place of `_process` and the residency's frame fence and pending flag, and reads the
  frame ledger through `rows()`; `test_blackout.gd` (12 to 6) counts lit windows through
  `Building.window_texture()`; `test_city_decay.gd` (13 to 2) recovers storefronts through
  `ground_floor_texture()`; `test_power_station.gd` (5 to 4) reads the ledger through `rows()`.
- The residency and blackout suites build a fresh `RunState` and hand it to each city as
  `City.run`, so they no longer touch the `GameState` autoload (13 lines to 0), the first suites
  moved under `run-state-handed-in.md`.
- Every check kept; the residency suite gains four. The rewritten checks fail under mutations of
  the residency fence and budget, the ground clock, the lit-window power rule, the storefront
  picture and the recorder's draw kind.

**Not done:** no planner "place this at this site" entry was needed; the reads of `Building`
drawing privates no game class reads stay and are listed, since a public name would be a member
only a test reads (records -44 and -47); the residency and blackout suites share one city across
their tests by design and fail run in reverse, which `tests-isolated.md` covers.
