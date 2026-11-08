# minty-quail — The drawing classes' members only their own class uses become internal · 2026-11-07

minty-quail's `tests-own-class-members.md`, the presentation members, in #1238, a commit per class;
with it the CI check's `[own file only]` group is empty.

**Built.**
- **`BadgeModel.watch`** becomes `_watch`. `test_badge_model` shows forgetting through the badge (a
  closing truck's badge goes once the truck is no longer handed over, and handed over again it is a
  fresh thing, not badged on its first frame back); `test_danger` drives a real fire engine at the
  edge and asks `announcing()` for its badge, then for its absence once the engine is retired. The
  check that the same Dictionary came back next frame, which held only the allocation, is removed.
- **`WalkerLook.gait_phase`** becomes `_gait_phase`: the tests restart the look, `advance()` it the
  distance whose phase they mean and read `gait_frame()`, and the same ground in two ticks lands on
  the same frame as in one.
- **`BuildingShadows.compute`** becomes `_compute`: the suite hands a `BuildingShadows` footprints
  and the `RecordingShadowDrawer` and reads the tiles each chunk draws (joined buildings as their
  union, a disjoint neighbor, no tile drawn twice or dropped, each chunk only its own tiles); it
  awaits a frame per scenario, so it runs slower.
- **`PosterArt.compose`** becomes `_compose`: the test prepares an art over the real atlas and checks
  the picture `texture_for()` answers pixel by pixel against the baked poster, mask and overlay.

**Choice where the design was silent, open to overturn:** the posters test reads real atlas pixels
and does not repeat the blend arithmetic for partly transparent overlay pixels, which RGBA8
rounding makes unreliable.
