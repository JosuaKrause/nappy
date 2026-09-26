## M116 — Wider storefronts and human-sized doors, 2026-09-12

[PLAYTEST-61](../playtests/PLAYTEST-61.md) asks: "store fronts have too small doors (compare eg
with the home door) and are not wide enough stores should be double each."
The [supplied frame](../evidence/playtest-61-2026-09-12/run-043335-seed255862635-v0.8.2-704-g4f3cfb7/asked/002-attempt2-asked.png)
shows a commercial frontage at tile 70,57 on day 1, seed 255862635. The complete player run is
preserved with it. The old store occupied 32×32px with a 9×23px door, beside the home's 26×34px
entrance.

Each store now occupies two columns: a 64×36px SVG with a 26×34px entrance, across all four
plain, awning and shuttered families. The renderer seeds one variant, awning roll and shutter
severity per store, and paints its whole frontage after the wall cells so a neighboring cell
cannot cover half of it. Source height determines the offset to the existing ground line;
ordinary wall bases keep their original placement. Windows immediately above a storefront move
2px north, including an odd end column's window, so tall and shuttered sills stay complete.

**Choices where the request was silent:** an odd final column remains ordinary wall, and a
one-row facade carries no storefront because a full-height entrance cannot fit. These are
presentation choices open to revision; building footprints, sidewalk collision and degradation
rules do not change. The complete stores retain the four existing display identities and muted
materials. A scaled old drawing with a larger door layered on top was rejected internally
because it collided with displays and canopy geometry; the final family uses native coordinates.

The import/boot check, doc/XML lint and focused `city_decay` suite verify the renderer and
degradation wiring. All twelve final sources were rendered by Godot and inspected at
[native scale](../evidence/m116-storefronts-2026-09-12/storefronts_1x.png) and
[3× scale](../evidence/m116-storefronts-2026-09-12/storefronts_3x.png): columns are grocer, café,
pharmacy and sign shop; rows are plain, awning and shuttered. The remaining human scale judgment
is listed in `REVIEW.md`.

The [gameplay still](../evidence/archive/session-captures/2026-09-12/m116-storefronts-seed255862635-day1.png)
shows the same commercial block at normal 1280×720 scale, day 1 and seed 255862635. A temporary
DevRig spawn target placed the player at tile 70,57; the capture waited four seconds with
`--svg --invincible --no-title`, and the temporary target was removed. The row shows four
complete stores in the space occupied by eight in the original frame. This is visual evidence,
not a played verdict on difficulty.
