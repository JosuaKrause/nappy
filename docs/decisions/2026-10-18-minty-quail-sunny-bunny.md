# minty-quail — The touch, HUD and orientation suites drive public seams (tests through public seams) · 2026-11-02


minty-quail's `tests-public-seams.md`: the touch, HUD and orientation suites. The item stays open for
the reads they keep.

**Built.**
- `test_touch.gd` pushes touches and clicks through `Viewport.push_input(event, true)`, lets real
  frames pass, and reads the `Input` actions `TouchControls` presses (which the game's `Stroller`
  reads) and `TouchControls.current_heading()`; a probe node hears the `pause` action as `main` does.
  `TouchControls.use_clock(clock)` hands the double-tap window a clock, as `ModeButton.use_clock()`
  does.
- `test_hud.gd` hands the HUD a `RunState.new()` of its own, configures it as `main` does
  (`configure()`, `use_touch()`, `use_run()`), drives it through `EventBus` signals and real frames,
  and reads its labels; the pause lesson's stands use a real `Stroller` under `Engine.time_scale`.
- `test_orientation.gd` boots `main` with a scratch save and `--touch` in a portrait window, and
  checks every screen layer carries `ScreenOrientation.rotation_transform()`.
- Private reads: touch 205 to 1, HUD 153 to 0, orientation 19 to 0; hand-called frame lines to 0.
  Checks: touch 295 to 300, HUD 146 to 142 (the lesson flags read as the lessons they cause, four
  state reads merged; nothing dropped), orientation 40 to 43. Seventeen mutations each fail a suite;
  a detention that banked its time passed the first detention test, so the test now earns part of a
  stand before the detention begins.

**Open to overturn** (the builder's choices where the brief was silent): `TouchControls.use_clock()`
with its wall-clock default, by the pattern of the other UI clocks; the HUD suite's teardown
emitting `EventBus.day_started` to restore the visit counter's day.
