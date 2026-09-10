# Sideways stair source review

These are source compositions of the prepared SVGs, rendered by Godot's
`Image.load_svg_from_string()`. They show artwork and placement examples; none of the three
assets has a runtime binding. The two supplied geometry references are retained in
[stair-layout-reference-2026-09-10](../stair-layout-reference-2026-09-10/).

`sources-native-and-3x.png` compares the interior staircase, fire escape A and fire escape B,
left to right. Each column contains a direct 3× SVG raster and its native-size counterpart on
an opaque neutral background. The individual `stair-down-*` previews retain transparency;
individual `fire-escape-a-*` and `fire-escape-b-*` previews use the neutral background.

`two-interior-stairwells-native.png` places exactly two stairwells at the ends of a corridor:
the left copy is mirrored and the right copy is unmirrored, so both upper/lower landing sides
face the hallway. It uses the existing hallway floor, hallway wall and stairwell floor SVGs.
The native composition is 288×112; its `-3x` companion enlarges those native pixels with nearest
filtering. The projected upper landing is a different storey, not an additional entrance on
the displayed corridor floor.

`fire-escapes-on-facade-native.png` places both 48×64 overlays over tiled `wall.svg` tinted
`#a99a87` and unmodified `window_dark.svg`. It demonstrates the transparent gaps between
opposing flights and between balusters. The native composition is 160×96; its `-3x` companion
enlarges the native pixels with nearest filtering. This is a facade composition example, not
a count or spacing rule for runtime placement.

| Source | Canvas | Drawing anchor | Native alpha bounds (x, y, width, height) | Landing reference points |
|---|---|---|---|---|
| `assets/interior/stair_down.svg` | 64×64 | (32, 64) | (1, 1, 62, 63) | Upper (8, 10), intermediate (56, 34), lower (8, 58) |
| `assets/buildings/fire_escape_a.svg` | 48×64 | (24, 64) | (1, 3, 46, 59) | Upper (7, 12), intermediate (41, 35), lower (7, 59) |
| `assets/buildings/fire_escape_b.svg` | 48×64 | (24, 64) | (1, 3, 46, 59) | Upper (41, 12), intermediate (7, 35), lower (41, 59) |

The interior canvas represents a 2×2-tile projection. Landing reference points lie on the
visible front edge of each platform, rather than describing collision or a floor-transition
trigger. Mirroring the interior replaces each x coordinate with `64 - x` and keeps the drawing
anchor fixed. Runtime map placement and transitions retain the chosen building side under
M102, the finale: out of the apartment, out of the city. Exterior placement belongs to
M106, roofs, fronts and street trees.

The interior uses concrete stringers and solid risers. The fire escapes use thin metal
stringers and open risers. Both use horizontal treads, vertical balusters and two opposite
handrail slopes; none narrows the flight toward the screen bottom. Fire escape B reverses the
landing layout and uses slightly warmer metal. These are layout variants, not animation frames.

Verification: XML validation with `xmllint --noout`, Godot native/3× source review, the two
assembled comparisons, `./tools/check.sh`, and `./tools/lint.sh`. No gameplay behavior changes
or test-suite changes accompany these source drawings.
