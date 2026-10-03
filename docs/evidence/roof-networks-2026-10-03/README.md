# Connected vent networks in engine context

`roof-networks-supported.png` is the current Godot 4.7.2 native-scale still. Five manually
arranged lots use generated layouts; the sixth is an explicitly labeled vertical-only fixture.
Every vertical-only cell has a support foot cropped from the accepted duct source, attached at
the same seam as its shaft. The fixture is a placement check, not a generated-distribution claim.
It uses the same engine, dimensions and save protection as the early still described below.

Current still SHA-256:
`22ce505ca4bb3cd1f104a6d8ab564710050fda42ce92e72681ae247618baa6fc`.
Current capture Building source SHA-256:
`59070f9af988a71ec7cc47632b8049c1b1f717effb59a3f05035c0c3f3d2247b`.

`roof-networks.png` is an early Godot 4.7.2 engine still, 1280×720 at native 1× scale.
The six building lots are manually arranged, as the visible caption says. Their roof furniture
and networks use ordinary seeded Building placement, variants 0 through 5, without seed search.
Runtime roof, facade, sidewalk and road textures supply context. This demonstrates appearance
and topology variation, not ordinary city distribution, motion, collision or player occlusion.
No invincibility is used; the review scene carries `--no-save` and has no gameplay save owner.

## Sources and assembly

No new raster art is painted or generated. The accepted source is
`art/illustrated/roof-equipment/duct_run.png`, SHA-256
`fbee2fcb5032e2f1be394bd3ac85c407348634676105ea2b052c397441f067af`.
Its exact generator prompt, raw output and deterministic native registration remain in
[the roof-family recipe](../roof-obstruction-pngs-2026-09-30/GENERATION.md).

`Building.RoofObject._draw_duct()` reads three rectangles from that native 64×64 texture:
horizontal mounted span `(18,44,24,20)`, vertical span `(53,26,10,16)` and the attached
support `(52,55,12,9)` for cells without a horizontal run.
They retain the approved galvanized material, ink and attached horizontal supports. The existing
rectangles are cropped and scaled along each occupied cell's connected axes; vertical spans draw
first and horizontal spans cover their junction. Pure vertical spans reach the support seam
at local y=-8; their separate foot occupies y=-9 through 0. No rotation introduces visible
away-facing mouths.
The same source remains in both atlas bake modes. The joined appearance remains open to review.

The topology grows a seeded tree inside `roof_interior_cells()`, including eligible extensions.
Each added cell touches exactly one prior cell. Its size is drawn from three cells up to one less
than the existing roof furniture budget; a smaller budget retains ordinary compact furniture.
Reservations exclude all other equipment. These length and branching choices are implementation
choices open to correction, not a separate player-approved topology rule.

## Reproduce

Fetch `refs/pull/441/head` before checking out the evidence commit if working from a fresh clone.
The supported still's runtime and rig source is
`473dd99e1c680b9f3cbb67d895dab26c1f4f5fb7`; check out that revision to reproduce it.
Use a fresh checkout so the output cannot overwrite retained evidence. Run `./tools/check.sh`, then:

```sh
"${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}" --path . --resolution 1280x720 \
  --disable-vsync scenes/dev/roof_network_preview.tscn -- --no-save
```

The scene exits after writing `roof-networks-supported.png`. For the early image, check out
`908f73fdbb50a78a1d52d62e5dbd86f42eede4b7` after fetching the durable PR ref. Its network rig
uses the early capture's layout, split from the roof-family scene to preserve that older family's
reproduction command; only unused family constants and comments differ from the captured rig.
The current supported rig adds the explicit vertical fixture and support crop described above.

Early still SHA-256: `24739d13336f5a67a928df4413860ab234989b79c1770f7afcad44e1e1345e8e`.
Early capture Building source SHA-256:
`e1a018490a6a7e52b8617cedb229d6877b1c628b1691be2a1d71e26813102821`.
