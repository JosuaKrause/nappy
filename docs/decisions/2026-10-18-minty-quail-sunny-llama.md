# minty-quail — The halo's, the excitement sources' and the visible view's suites are typed · 2026-11-11

**The ask.** Test code is typed as the code it tests is ("we type when we can", inbox #1280 in
olive-ferret), and a test reads its subject only through methods (inbox #1182 in gray-dolphin):
`typed-everywhere.md`, one pass per module. This pass is the halo and what the screen shows; its search
covers `EntityHalo`, `ExcitementHalo`, `ExcitementSource` (with `EventExcitement` and
`CrowdExcitement`), `ExcitementSources`, `VisibleView`, `DrawnView`, and the crowd agent's
`excitement` read in `test_wall_shield` that the crowd's record (tiny-elk) names.

## What was built

- **Seven files parse without their file-level opt-out line**, which each loses: `tests/halo_rig.gd`,
  `test_excitement_source.gd` and `test_drawn_view.gd` (`untyped_declaration`), `test_halo.gd` and
  `test_wall_shield.gd` (`untyped_declaration`, `unsafe_method_access`), `test_prediction_reuse.gd`
  (all three) and `test_visible_view.gd` (`unsafe_method_access`). The rig keeps every function's name,
  argument order and answer; the four files that preload it pass.
- **Reads and writes converted to methods the game calls**: a source's `rim` is set through
  `use_rim()` (the rig, `test_halo`'s churning source and `test_prediction_reuse`'s four fakes); her
  velocity, sensitivity and decay rate are set through `set_player_at()`, the call the halo makes each
  frame, which each test write followed with the same values; a live event's `excitement` is asked
  through `EventInstance.source()` and a crowd body's through `CrowdAgent.mood()`, in all seven files,
  wider than the one read the brief named, by the rule that a read through a parent the parent answers
  is converted (the builder's).
- **Loops take their writers' types**, a scene is instanced through a typed `PackedScene`, and the two
  live-net checks of `test_prediction_reuse` are one function over a source and a counter. No check
  deleted or moved; nothing under `src/` or `tools/test_only_members.txt` changed. The private members
  `test_prediction_reuse` writes by name stay, as `tests-public-seams.md` names them.

## Fields read and written, by class

Built with `tools/field_answers.py --counts` on the seven files, each named method read in its class.

- **`ExcitementSource`** (searched): `rim`, written → `use_rim()`; `player_velocity`,
  `player_sensitivity`, `player_decay_rate`, written → `set_player_at()`; read → no method: `body`,
  `landed_ever`, `player_at`, `player_expected_total_gross`, `rim`; written → no method:
  `on_first_landing`, `outranked`.
- **`VisibleView`** (searched): `view`, `joystick`, read → no method; `controls`, written → no
  method.
- **`EventInstance`**: `excitement` → `source()`; `age`, written → `resume()`, `setup()` and
  `notice_her_at()` assign it within other work, none is the test's write; `EventInstance.Figure.age()`
  is on a view no public method hands out.
- **`CrowdAgent`**: `excitement` → `mood()`.
- **`CarTurn`**: `travelled`, written → `travel_on()` adds to it, the suite sets an absolute distance;
  `sweep` → no method.
- **`Crowd`**: `sources` → no method. **`EventManager`**: `sources`, `world`, `streaming` → no method.
- **`InteriorScene`**: `map` → no method. **`TouchControls`**: `covering`, `rotated` → no method.
- **`DangerEdge`**: `atlas`, `model` → no method. **`WorldContext`**: `excitement_sources` → no
  method. **`WorldMap`**: `world`, written → no method.
- **`PursuitSpec`**: `speed` → no method. **`EventFlock.Bird`**: `at`, `heading`, `speed` → no method.
- **`GroundShape`**: `kind` → no method; `half_extents`, `half_length`, written → no method.
- **`EventDef`**: `id`, `duration`, `pursuit`, `solid_parts`, `speed` → no method; `shape`, written →
  `solid()` also sets `obstructs_radius`, so it is not the test's write.
- **`LaneMover`**'s lane: `Lane.is_vertical()` and `Lane.strategy()` answer on the `lane()` view.
- **Not told**: the fakes' own inherited `rim`, and `source.live` on a test's own class in
  `test_visible_view`.

## Verified

At test parity: the seven files' suites, `test_halo_behind` and `test_checkpoints` pass; the typing
census, `./tools/check.sh`, the field-read and the test-only-member checks pass.
