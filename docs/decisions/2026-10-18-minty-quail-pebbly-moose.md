# minty-quail — The stroller draws from one public pose, and the stroller suites read it (tests through public seams) · 2026-11-02


minty-quail's `tests-public-seams.md`: the stroller suites. The item stays open for the crowd and
player suites the same agent did not reach.

**Built.**
- `Stroller.pose(gait)` returns a `Stroller.Pose` (the view sector, the mirror, the walk phase, the
  gait frame, the baked path of each mother pose, the pram's path, and the pram's drawn offset and
  size); `_draw()` builds it once and `_draw_mother()` and `_draw_pram()` paint from it, so a test reads
  the object the game draws from. A first review found nine members public that only tests read;
  they are gone or private again, and `mother_gait_frame()` stays public for the scene recipes'
  snapshot. The stride rate is `WalkerLook.GAIT_RATE` (0.09) in the stroller and its test.
- `test_stroller.gd` and `test_stroller_gait.gd` read nothing private and step real physics frames
  with the move key held; `test_player_presentation.gd` reads one private member (`main._make_player()`).
  `test_baby_world.gd`'s boots are handed a scratch-path save.
- Checks: test_stroller 288 to 288, test_stroller_gait 84 to 96 (its per-quarter checks became
  whole-walk checks, per state), test_player_presentation 373 to 469 (each direction, frame, state and
  sex also checks the view settled and a picture resolves), test_baby_world 15 to 15. Breaking the
  stride rate, the gait loop's order, the view hysteresis, the pram offset's cache or the mirror each
  fails a suite.
