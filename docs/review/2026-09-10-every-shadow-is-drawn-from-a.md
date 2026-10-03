**Every spread stands on a capsule, and nobody has looked at one in play.** (How the shadows read
is answered: [minty-hedgehog](../playtests/2026-10-03-minty-hedgehog.md), statement 1, "this does
not read as shadow", and [silver-egret](../todo/2026-10-03-silver-egret/README.md) builds it.) A
barricade, a roadblock or a construction band is solid as a 48px-thick capsule rather than the disc
it used to be, so she can stand closer to it along the street than before. The sealing and pavement guarantees are asserted over the capsule in
`tests/test_shapes.gd`; whether a thinner body reads as *right* or as *a wall she can lean
through* is a played question, and the debug view's bounding-box layer (`3` in a debug build)
is the instrument to answer it with.
