# Rooftop equipment PNG generation

This folder preserves the generated source, exact prompt, reference roles, deterministic
registration and review sheets for the rooftop equipment family. The player permits this family
to be authored directly as PNGs without base SVGs. The rejected installed roof PNGs are never
generation inputs.

## First family source

`raw/roof-family-v1.png` is the built-in image generator's 1536×1024 RGBA result, SHA-256
`f113353b8142041106a2bca70465fa3773e11f7fd6bcf4d19ba6498cad9dfa67`. It is the first retained
proposal because it answers the two explicit rejection points: its water tower has a closed
conical roof, and its straight and elbow ducts stand on visible roof mounts. It also proposes
credible roof variety: two HVAC forms, two skylights, a vent group, an exhaust housing, a service
bulkhead, a mushroom fan and a pipe manifold.

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
