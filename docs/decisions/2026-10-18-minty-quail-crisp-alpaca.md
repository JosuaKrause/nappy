# minty-quail — The test items say only what is still open · 2026-11-06


An audit of the test items under `docs/todo/2026-10-18-minty-quail/` against `main`, once the
own-class pass had merged for every owner. Docs only; no `src/` or test change.

**Measured.** `tests-public-seams.md`'s two count commands print nothing outside `tests/shared_state.gd`
and `tests/test_prediction_reuse.gd`, the two files the item exempts with their reasons. The CI
check's `[own file only]` group holds no line. `tests/test_scene_recipe_activity.gd` is the one suite
that boots `scenes/main.tscn` with no save handed in. A mutation run, `DayDirector.start_day()`'s call
to `prepare_city_scenery()` replaced by `pass`, left `test_camera_start.gd` at 24 checks, 0 failures,
so the item's note that no test catches that removal still holds.

**Deleted from the items, each covered by a record.**
- `tests-public-seams.md`'s per-suite account of every converted suite (the resistance, event,
  crowd, city, interior, telemetry, scene recipe, save, boot, dev-capture and drawing suites, and the
  "where it stands" list of files still to convert, now none): the records titled "(tests through
  public seams ...)" and "stop calling members only tests call", from `minty-quail-43` and `-44` to
  `minty-quail-woolly-lark`, one per slice. Their per-suite descriptions are in those records.
- `tests-unseen-reads.md`'s sections 1 (no private member reached by a missed route: spry-newt),
  2 (hand-edited collections and state: tawny-sparrow, spotted-goose, the run and city writers
  of #1139), 3's per-owner lists of members only tests call, now internal, gone or kept with their
  reasons (sunny-marmot, olive-sparrow, leafy-walrus, silver-stork, downy-rabbit, freckled-walrus,
  sandy-lark, breezy-raven, spotted-lynx, tawny-squirrel, lilac-walrus, golden-chipmunk,
  dappled-sparrow, grassy-squirrel), 4 (the city suites and the rig press suite: tawny-squirrel,
  downy-rabbit) and 5 (a proposed split into builds with nothing left to split).
- `tests-isolated.md`'s incident paragraph (the order-dependent `test_touch` failure, not
  reproduced: amber-bison), and the runner's shared-state check and shuffle and repeat, built
  (`minty-quail-49`, pebbly-quail).
- `tests-own-class-members.md`'s owner-by-owner build, merged for every owner (the records ending
  "become internal", #1112 to #1141).
- `comments.md`'s note that the three events files state the rule (the event instance's, catalogue's
  and definition's comments: the records of #1137 and #1140).

**Rewritten to the present.** `tests-public-seams.md` states the rule, its two exempt files, the
accepted wall-clock hand-ins, the drawn-art rule, the public steps a suite drives by hand with their
reasons, and the open gaps. `tests-unseen-reads.md` keeps the four readings of the rule, how a test
writes game state and the fixture writes that stay, the members only tests read that stay with their
reasons and the two open design questions (a focus source for the crowd, a log handed to the
observer and gameplay classes), and the DEV-only tier. `tests-isolated.md` keeps the open
observer-count declaration, the boots that drift, and the two places a test still touches something
real. `tests-own-class-members.md` keeps the colliding-name members, about fifty, that a qualifying
check finds.

**Rejected.** Deleting a whole item file: each still holds open work or a rule the CI check's list
cites (`tests-public-seams.md`'s "Build paragraph" and the exception for `step_the_encounters()`).
Renumbering section 3 of `tests-unseen-reads.md`: `tools/check_test_only_members.py`'s docstring
cites that section's method.
