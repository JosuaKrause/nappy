# minty-quail — The scenery layers and the building shadows draw through drawers they are handed (tests through public seams) · 2026-11-05

minty-quail's `tests-public-seams.md`: `tests/test_scenery_animation.gd`, `tests/test_blocks.gd` and
`tests/test_building_shadows.gd`. The world: `src/city/` (a new `SceneryDrawer` and `ShadowDrawer`),
and `src/events/` for the scenery an event leaves.

**Built.** Two drawer kinds, in the pattern of the roof, front and event drawers. A scenery layer
still decides which of a picture's two frames shows and hands every picture to its `drawer`, which
draws it; the city hands one `SceneryDrawer` to its street decals and, through the roof drawer's
constructor, to every vent's turning rotor, and the event drawer hands one of its own to the
scenery behind a crash or a burst water main. `BuildingShadows` hands each chunk's tiles to its
`drawer`, a `ShadowDrawer` the city hands in, which holds the shading the chunk used to do itself.
The suites read what was drawn off recording drawers: the rotors' and the event layers' pictures
flipping, the street tree beds the decals draw, and each chunk's shadow tiles, which equal the
whole city's shadow union for that chunk; a counting filter handed through `BuildingShadows.falls_on`, as the city hands it the map's stretch test, shows streamed shadows work out no distant tile before a chunk is prepared. Stills of the same seed and moment before and after
differ in no scenery or shadow pixel, and a draw allocates nothing.

**Choices, open to overturn.** Event scenery has a drawer of its own rather than the city's (the
drawer holds nothing, so sharing would change no pixel); the roof drawer carries the rotor's drawer
as a constructor parameter rather than `Building` holding a second member; the scenery drawer is
told textures, since layers hold textures from three atlas groups; one shadow-drawer call per
chunk pass (the builder's calls). The roof preview rigs under `src/dev/` and
the scenery animation probe's read of `Building._vent_timer` are left as they are.
