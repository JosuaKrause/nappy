**Nearby scenery loading has its measurement, and its docs and probes are true**
([#445's review](https://github.com/JosuaKrause/nappy/pull/445#pullrequestreview-5400255257),
prepare nearby city scenery and unload distant visual data, and
[#452's review](https://github.com/JosuaKrause/nappy/pull/452#pullrequestreview-5400265791),
silky-rabbit, spread nearby ground preparation across frames). The runtime was found sound in both:
gameplay reads no evictable visual data, and no half-prepared ground is ever drawn.

- **The measurement M159's item asked for was never taken.** #445 deleted
  `prepare-static-visuals-ahead-of-view.md`, whose gate was "Compare startup/day-start latency,
  complete-frame median/tails/max, memory ... Accept only a measured benefit". `results.json`
  records `boot_main_usec` but compares it with nothing; the waiver rests on "the measurements were
  already done, no? in 444", and #444 measured a detached probe. Measure boot, day start, frame
  tails and memory at the parent of #445's merge against `main`, and file it under M159 — or the
  player waives it, in their words.
- #444's parked probes `tests/probes/lazy_scenery_{city,measure,routes}.gd` no longer run, since
  `City/Ground` is no longer a `TileMapLayer`; delete them and their `.uid` files (the #444 reruns
  check out pinned revisions, so nothing is lost).
- Water is one surface per ground chunk, phased by `SceneryGround`'s clock, but
  `docs/ARCHITECTURE.md` (its water paragraph), `docs/GRAPHICS.md` (its water lines) and
  `src/city/scenery_water.gd`'s header comment describe the old arrangement. Rewrite all three.
- `src/city/building_shadows.gd`: `_by_chunk` is never read, and the `if not streamed` it guards is
  always true there. Remove both.
- `src/city/city.gd`: the docstring #445 rewrote keeps "This used to be ~120 lines…", which the
  present-tense rule rules out.
- `src/city/city_decals.gd`: at day start the refresh prepares decal chunks synchronously at the
  previous day's view, and they are evicted a moment later: wasted work to remove.
- `src/city/city.gd`'s `close_ground()` now keeps the route-kerb tint during a live closure, a small
  visible change nobody mentioned. Say so in the M159-4 record.
- `tests/test_scenery_residency.gd` (while the stepped preparation stays; PR #455 holds the player's
  choice between keeping it, restoring atomic preparation, or a dev flag): the check "camera relocation completes pending destination
  ground before returning" never starts from a pending region — the `close_ground` before it cancels
  the job — so nothing covers what keeps a half-built region off screen. A mutation that lets the
  guard skip pending regions passes the whole suite. Make the region pending with `prepare_step`
  before the relocation and assert the same layer lands in `chunks`; add a case for the guard
  without a relocation. The check "synchronous guard completion promotes the existing pending
  owner" never compares the layer; assert `ground.chunks[key] == owner`.
