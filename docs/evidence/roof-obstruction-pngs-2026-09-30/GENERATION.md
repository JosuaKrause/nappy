# Rooftop equipment PNG generation

This folder preserves the generated source, exact prompt, reference roles, deterministic
registration and review sheets for the rooftop equipment family. The player permits this family
to be authored directly as PNGs without base SVGs. The rejected installed roof PNGs are never
generation inputs.

## First family source

`raw/roof-family-v1.png` is the built-in image generator's 1536×1024 RGBA result, SHA-256
`f113353b8142041106a2bca70465fa3773e11f7fd6bcf4d19ba6498cad9dfa67`. It is the first retained
concept because it answers the two explicit rejection points: its water tower has a closed
conical roof, and its straight and elbow ducts stand on visible roof mounts. It also proposes
credible roof variety: two HVAC forms, two skylights, a vent group, an exhaust housing, a service
bulkhead, a mushroom fan and a pipe manifold.

The player accepts these concepts and this drawing style, while asking that their perspective,
scale and placement be adapted to the game. It is therefore concept evidence rather than runtime
art.

The generator returned true RGBA. Per-cell alpha bounds and neutral fringe checks belong to the
registration recipe; the existence of an alpha channel alone is not treated as proof of a clean
cutout.

### References and roles

| Input | SHA-256 | Role |
|---|---|---|
| `docs/style-references/graphics-reference-urban-01.jpeg` | `8ae95f917da8dae7abb22508a61efac3dff2ccbef69b80b859bb2a828b10cc5d` | Approved expressive ink, comic material planes and deliberate shadows only; its interface and scene content are excluded. |
| `docs/style-references/graphics-reference-cardinal.jpeg` | `637712546f9f336eb7bdd58810b8dc5d75935651250f7bea5ab116748116b7a7` | Approved gameplay-scale outline, muted palette and cardinal projection only; its interface and debug text are excluded. |
| `docs/reference/rooftop-duct-run-01.jpg` | `0124c72128f3f1a4b3a1c82d7c3c0aaad989ebd33d3a424357ecb16a0cbd86be` | Real rectangular duct construction, short support legs, elbows and connected equipment. |
| `docs/reference/rooftop-hvac-units-01.jpg` | `c9c52bf971585498f9be65b1943887bc0996475c2c6e8365e35eccd9fbfc06b1` | Real cabinet curbs, condensers, vent stacks and utility pipework. |
| `docs/reference/rooftop-skylights-01.jpg` | `fdcf3eb895f048784442baa562ae2cdbb37863ed824743d8c72c7d6c2a07f736` | Real low skylight forms and broader ordinary roof variety. |

### Exact prompt

```text
Use case: stylized-concept
Asset type: coherent rooftop-equipment sprite family source sheet for a small 2D route-planning game
Primary request: create a fresh rooftop equipment family from scratch, grounded in ordinary New York flat-roof machinery and the supplied photos.
Input images:
- Image 1 (graphics-reference-urban-01.jpeg): approved style reference only for expressive dark ink contours, warm restrained comic color, simple material planes, and deliberate cast shadows; exclude its UI, text, people, vehicles, and scene composition.
- Image 2 (graphics-reference-cardinal.jpeg): approved style reference only for the game's muted palette, cardinal/top-down gameplay readability, outline weight, and compact material shading; exclude all UI, debug text, characters, streets, and buildings.
- Image 3 (rooftop-duct-run-01.jpg): subject reference for rectangular duct construction, visible short support legs, connected elbows, roof penetrations, and weathering.
- Image 4 (rooftop-hvac-units-01.jpg): subject reference for credible box HVAC housings, base curbs, vent stacks, and utility pipework.
- Image 5 (rooftop-skylights-01.jpg): subject reference for low skylights and ordinary roof variety.
Scene/backdrop: a transparent background; no roof slab and no environmental scene, only isolated equipment.
Subject: a tidy 4-column by 3-row source sheet with exactly twelve isolated objects, one object centered in each generous cell with clear transparent gutters. Fixed order, left to right, top to bottom:
1) closed cylindrical wooden rooftop water tower with a clearly capped conical roof, metal hoops, and four sturdy timber feet;
2) large rectangular HVAC cabinet seated on a raised metal roof curb;
3) compact HVAC condenser with a dark top fan grille and visible base feet;
4) low multi-pane sloped skylight on a curb;
5) low pyramidal skylight on a curb;
6) three short vent stacks rooted in one flashing plate;
7) long straight rectangular duct span, three visible short support legs underneath, connector collars at both ends;
8) matching 90-degree rectangular duct elbow, two visible short support legs, connector collars aligned to the straight span;
9) industrial exhaust housing on a curb with one centered circular dark opening sized for a separate rotor overlay;
10) modest rooftop stair/service bulkhead with a shallow sloped cap and one vent louver;
11) mushroom exhaust fan on a flashing curb;
12) compact insulated utility-pipe manifold on visible brackets.
Style/medium: polished hand-drawn comic game sprites, crisp dark brown-black outlines, slightly irregular authored contours, restrained cel shading, small expressive rust and grime accents, no photorealism.
Composition/framing: consistent three-quarter top-down/cardinal game projection, light from upper left, every object fully visible, no overlaps between cells, uniform visual scale suitable for later native 32–64 px extraction.
Color palette: muted galvanized gray, charcoal, aged cream, desaturated blue-green, restrained rust, dark warm timber on the tank; avoid bright saturated colors.
Materials/textures: equipment must feel weight-bearing and installed: every duct has explicit supports and a contact shadow, every cabinet has a curb or feet, every skylight has a roof curb, pipes have brackets. Shadows stay immediately beneath each object and do not become a shared ground plane.
Constraints: true transparent background; no labels, no numbers, no text, no watermarks; water tower must be completely closed by a conical roof, never open; ducts must visibly connect and stand on roof mounts, never float; preserve a coherent family identity across all twelve objects.
Avoid: whimsical props, antenna clutter, satellite dishes, loose household objects, people, birds, vegetation, rooftop scene, painted checkerboard, white background, drop-shadow halo, open tank, unsupported duct strips, disconnected duct ends.
```

Generation used the built-in image generator with transparent background enabled. Reproduction is
nondeterministic; all extraction, registration and review assembly from the saved raw result is
deterministic and recorded here with the final installed family.

## Cardinal family source

`raw/roof-family-cardinal-v2.png` is the built-in image generator's 1536×1024 RGBA result,
SHA-256 `18bf57e7da22c4db095d1490a69010cdfa32519057399cab177f1a0d1995dc2e`. The accepted first
sheet supplies concept and style only; the approved cardinal gameplay reference supplies the
projection. The result keeps horizontal roof-grid edges screen-horizontal, keeps vertical
supports screen-vertical, and leaves tall units at their full height above a bottom-center roof
anchor. Its diagonal elbow is not a runtime input; the separate continuous L-run below replaces
that unresolved cell.

### Exact cardinal-family prompt

```text
Use case: style-transfer
Asset type: game-ready source sheet for rooftop equipment in an orthographic cardinal 2D game
Primary request: adapt the accepted rooftop-equipment concepts into the game's screen-facing cardinal projection while preserving their exact comic style, material identity, scale relationships, and installed construction.
Input images:
- Image 1 (roof-family-v1.png): accepted CONCEPT AND STYLE AUTHORITY. Preserve these twelve equipment designs, dark expressive ink, restrained cel shading, rust accents, material identity, closed conical water-tower roof, sturdy feet, roof curbs, and visibly supported duct construction. Do not preserve its isometric/diagonal camera.
- Image 2 (graphics-reference-cardinal.jpeg): PROJECTION AND GAMEPLAY PRESENTATION AUTHORITY. Match this game's orthographic cardinal view: the screen x axis stays perfectly horizontal, the screen y axis stays perfectly vertical, building roof edges remain screen-horizontal and screen-vertical, and standing objects face the south/front of the screen without a diagonal vanishing point. Exclude interface, debug text, people, streets, and scene content.
- Image 3 (graphics-reference-urban-01.jpeg): approved comic line, warm restrained color, authored contours, and deliberate small shadows only. Exclude interface, text, people, vehicles, and scene composition.
- Image 4 (rooftop-duct-run-01.jpg): real subject reference for supports, connector collars, roof penetrations, and weight-bearing duct construction.
- Image 5 (rooftop-hvac-units-01.jpg): real subject reference for curb-mounted HVAC, vent stacks, and ordinary service equipment.
Scene/backdrop: true transparent background; isolated sprites only; no roof slab and no environmental scene.
Subject: a clean 4-column by 3-row sheet with exactly twelve separated objects in the same fixed order as Image 1, left to right and top to bottom:
1) tall closed wooden rooftop water tower with conical roof, hoops, cross-braced feet and a narrow one-cell roof footprint;
2) large HVAC cabinet on a curb;
3) compact condenser on visible feet;
4) long low sloped multi-pane skylight on a curb;
5) low pyramidal skylight on a curb;
6) three vent stacks on one flashing plate;
7) long straight rectangular duct on three short mounts;
8) matching 90-degree rectangular duct corner on short mounts;
9) industrial exhaust housing on a curb, with a clean circular opening for a separate fan rotor;
10) roof service bulkhead with shallow cap and louver;
11) mushroom exhaust fan on a flashing curb;
12) compact pipe manifold on brackets.
Projection: STRICT orthographic cardinal game projection, zero vanishing point, no isometric diagonal. All front/south faces are screen-horizontal rectangles. Vertical supports and tower legs run straight up/down on screen. Straight duct runs exactly left-to-right on screen. The elbow turns from screen-horizontal into screen-vertical and its connector widths/heights match the straight duct. Skylight ridges run screen-horizontal or screen-vertical. Only top surfaces may be visible as shallow top planes; no object is rotated 30–45 degrees around the vertical axis.
Scale and placement: preserve realistic relative size and full silhouette. Tall equipment may extend well above its roof footprint and must NOT be squeezed into a square tile. The water tower, large HVAC, vent group, exhaust housing, bulkhead, fan, and pipe manifold keep their full height above a narrow bottom-center roof anchor. Low skylights keep a wider footprint and short height. The straight duct spans two roof cells; the corner occupies one. Leave clear transparent gutters around every complete silhouette for deterministic extraction.
Style/medium: preserve Image 1's polished hand-drawn comic style exactly: crisp dark brown-black outlines, slightly irregular authored contours, restrained cel shading, small rust/grime accents, muted galvanized gray, charcoal, aged cream, desaturated blue-green, and dark timber.
Lighting/mood: light from upper left; tight contact shadows directly below supports/curbs only.
Constraints: true transparency; no labels, no numbers, no text, no watermark, no checkerboard; water tower completely closed by a conical roof; every cabinet and skylight visibly seated on curb/feet; ducts connected in construction and never floating; coherent family identity.
Avoid: isometric camera, diagonal roof grid, diagonal yaw, perspective convergence, shrinking tall equipment into square cells, shared ground plane, disconnected ducts, unsupported metal strips, open water tank, whimsical clutter, satellite dishes, people, vegetation.
```

## Rejected continuous cardinal duct run

`raw/roof-duct-run-cardinal-v1.png` is the built-in image generator's 1536×1024 RGBA result,
SHA-256 `781a762c5dcf250be3dd1bec296d1adec2cbda8b6e0331a9a435d0d8a513d6da`. It replaces the
cardinal sheet's still-diagonal elbow with one continuous L-shaped assembly. The assembly occupies
the same three-cell L footprint as the existing straight-plus-corner placement, so density and
placement cost stays fixed while every joint becomes visually continuous. The player rejected it
after noticing that a fixed camera looking from the south should not see inside either its west-
or north-facing mouth. It is retained as human-rejected generation evidence and is not installed.

### Exact duct-run prompt

```text
Use case: style-transfer
Asset type: one game-ready rooftop duct-run sprite for an orthographic cardinal 2D game
Primary request: replace only the unresolved diagonal elbow concept from the accepted cardinal roof family with one physically continuous, screen-axis-aligned L-shaped duct assembly.
Input images:
- Image 1 (roof-family-cardinal-v2.png): FAMILY IDENTITY AND MATERIAL AUTHORITY. Match its straight duct's galvanized panels, dark ink outline, rust accents, connector collars, short square support legs, light direction, and comic shading. Do not copy its diagonal/isometric elbow.
- Image 2 (graphics-reference-cardinal.jpeg): PROJECTION AUTHORITY. Match the game's orthographic screen axes; roof grid horizontal edges stay screen-horizontal and vertical edges stay screen-vertical. Exclude interface, debug text, characters, and scene content.
- Image 3 (rooftop-duct-run-01.jpg): SUBJECT CONSTRUCTION AUTHORITY for installed rectangular ducts, short supports, continuous joints, and realistic roof contact.
Scene/backdrop: true transparent background, one isolated complete duct assembly only.
Subject: one continuous rectangular galvanized duct in an overhead/cardinal L footprint covering exactly three equal roof cells of a 2×2 grid: the entire bottom row (two cells left-to-right) plus the top-right cell. A horizontal two-cell arm runs perfectly screen-horizontal from the left edge to the right-hand turn. At the right-hand cell it turns exactly 90 degrees and continues perfectly screen-vertical upward through the top-right cell. The inner and outer elbow walls are continuous; there are no open or disconnected ends at the turn. Only the far left end and far top end show connector collars/openings. Put short visible support legs under the horizontal arm and under the vertical arm, each ending in a small square roof foot with a tight contact shadow.
Projection: strict orthographic cardinal, zero vanishing point, no diagonal yaw, no isometric diamond. Horizontal arm edges are screen-horizontal; vertical arm edges are screen-vertical. Show only shallow top and front/south planes needed for material readability, without rotating the assembly around the vertical axis.
Composition/framing: center the whole L with generous transparent gutter. Preserve the actual L footprint and full mounted height; do not squeeze it into one square. No grid, no roof slab.
Style/medium: exactly Image 1's polished hand-drawn comic style, crisp dark brown-black outlines, slightly irregular authored contours, restrained cel shading, muted galvanized gray, small rust and grime marks.
Constraints: true transparency; no labels, text, numbers, watermark, checkerboard, or shared ground plane; all joints continuous; support feet contact the roof; no floating parts.
Avoid: diagonal elbow, isometric projection, perspective convergence, separate pieces, mismatched connector sizes, unsupported duct strip, open gap at the turn, rooftop scene, people, clutter.
```

## Corrected continuous cardinal duct run

`raw/roof-duct-run-cardinal-v2.png` is the targeted built-in image-generator edit selected for
registration, SHA-256 `aef595d6170d395baf2f65bc0a69d0446fb6d6d7b6f7e8dc62afd838d58e6cda`.
It preserves the approved L footprint, supports and family style while showing opaque exterior
metal at both away-facing ends rather than impossible dark openings.

### Exact correction prompt

```text
EDIT TARGET: the supplied continuous L-shaped rooftop duct illustration. Preserve the exact L shape, cardinal screen-axis orientation, proportions, connected elbow, galvanized comic-ink style, orange weathering, clamps, bolts, support legs, roof feet, lighting, scale, and transparent cutout composition. Make only this projection correction: the open ends point west and north, away from this game's fixed camera, so neither opening interior is visible. Remove both visible dark hollow mouths and redraw those end faces as the opaque exterior/back-side metal surfaces that the camera would see from behind an away-facing open end. Do not add closed caps, grilles, extra equipment, or rotate any segment. Keep all existing supports and joints in place. Output a genuinely transparent background with no glow, haze, floor, checkerboard, text, labels, border, or shadow field outside the object.
```

The edit target was `raw/roof-duct-run-cardinal-v1.png`. No rejected installed artwork was an
input. Generation used the built-in image generator with transparent background enabled.

## Deterministic registration

Rebuild into a new, otherwise nonexistent directory, then verify that every rebuilt file is
byte-for-byte equal to its committed counterpart:

```sh
test ! -e /private/tmp/nappy-roof-rebuild
uv run python docs/evidence/roof-obstruction-pngs-2026-09-30/register_roofs.py all /private/tmp/nappy-roof-rebuild
uv run python docs/evidence/roof-obstruction-pngs-2026-09-30/register_roofs.py verify /private/tmp/nappy-roof-rebuild
```

The output root contains the eleven assets below their repository-relative
`art/illustrated/roof-equipment/` path and the review sheet below its repository-relative
`docs/evidence/roof-obstruction-pngs-2026-09-30/review/` path. The recipe never installs them.
Before creating the output root, it rejects an existing path and verifies both selected source
hashes. Repeating the `all` command above exits nonzero with `refusing existing output directory`.
An isolated-copy check with one byte appended to the copied cardinal-family source exits nonzero
with its expected and actual SHA-256 values, and the requested output path remains absent.

The recipe removes the generator's low-alpha neutral preview fringe, crops fixed non-overlapping
source cells, scales each complete silhouette into its stated native canvas, and registers every
object bottom-center at its roof foot. It lays the native files out at nearest-neighbor 4× for the
review sheet; it does not modify runtime art. `verify` checks dimensions, alpha registration and
exact bytes for all eleven PNGs and the review sheet without writing to either tree.

The installed canvases are `water_tank` 40×72, `hvac_large` 48×40, `condenser` 32×40,
`skylight_long` 56×24, `skylight_pyramid` 32×28, `vent_stack` 40×48, `duct_run` 64×64,
`industrial_vent` 44×44, `service_bulkhead` 48×52, `exhaust_fan` 32×36 and `pipe_manifold`
52×40. Every non-empty alpha bound reaches the canvas bottom and leaves both upper corners fully
transparent; the script fails if either registration fact changes.

The installed files were registered with Python 3.14.7 and Pillow 12.3.0. Pillow performs the
LANCZOS downsampling and optimized PNG write; these are the exact versions that produced the
committed bytes.

The [in-engine context frame](../m109-roof-context-2026-09-30/README.md) places all eleven runtime
regions on the game's roof, facade, sidewalk and street at native scale.
