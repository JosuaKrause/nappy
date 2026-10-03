# Roof equipment proportions and complete source outlines

`roof-scale.png` is a Godot 4.7.2 still at 1280×720, native 1× scale. Objects are manually
arranged and labeled on runtime roof, facade, sidewalk and street art. The separate regular
door is a scale reference; the same door appears in the actual facade below. This still shows
the requested proportions and silhouettes, not generated distribution or animation.
The scene carries `--no-save`; it has no gameplay save owner and uses no invincibility.

## Proportion choices

The player's [silky-bunny feedback](../../playtests/2026-10-03-silky-bunny.md) asks for smaller
standalone pipes and fans, a larger access room with a normal-sized door, unchanged water tank
and skylight scales, and the long skylight's missing left edge restored.

| Family | Runtime factor | Registered canvas width | Displayed canvas width | Reserved roof columns |
| --- | ---: | ---: | ---: | ---: |
| Vent stacks | 2/3 | 40px | 26⅔px | 1 |
| Industrial fan | 2/3 | 44px | 29⅓px | 1 |
| Exhaust fan | 2/3 | 32px | 21⅓px | 1 |
| Pipe manifold | 2/3 | 52px | 34⅔px | 2 |
| Access room | 4/3 | 48px | 64px | 2 |

The room source doorway is approximately 154px tall, within a 372px-wide source silhouette.
Registration fits that silhouette to 46px; the 4/3 runtime factor gives a doorway approximately
25.4px tall, comparable to the regular door's 26px opening. These factors are implementation
choices open to review. The room silhouette itself is about 61⅓px wide within its 64px canvas.
The unchanged reference families are the water tank, both skylights, HVAC, condenser and ducts.

`Building.RoofObject` scales the whole object about its bottom-center roof foot, so its rotor
inherits exactly the housing transform. Reservations derive from that displayed width; collision
remains the building's existing body. Compact fallbacks and scenery reconstruction remain live.

## Faithful extraction

No new artwork is generated or painted. The approved cardinal sheet and its prompt are preserved
in [the roof-family recipe](../roof-obstruction-pngs-2026-09-30/GENERATION.md).
Both the long skylight and manifold start left of their old x=1152 extraction boundary. The
source crop now begins at x=1105, in the clear gutter before each complete silhouette.

The skylight's cleaned source bounds grow from 353×160 to 383×160. Registration is height-limited
at 22/160 in both cases: the complete 53px-wide silhouette fits the same 56×24 canvas without
reducing its scale. The pipe manifold is fitted as a complete silhouette into its existing
52×40 canvas before applying the requested smaller runtime factor. Its previously missing left
pipe bend and foot are restored. Extraction rejects a silhouette touching either side of a crop.

`source-crops-4x.png` shows the registered PNGs at 4× before runtime scaling. The original
human-reviewed sheet remains unchanged at its September 30 path. Rebuild the corrected PNGs and
this new source sheet into a fresh directory, then compare them byte-for-byte:

```sh
uv run python docs/evidence/roof-obstruction-pngs-2026-09-30/register_roofs.py all /private/tmp/roof-scale-rebuild
uv run python docs/evidence/roof-obstruction-pngs-2026-09-30/register_roofs.py verify /private/tmp/roof-scale-rebuild
```

This uses Python 3.14.7 and Pillow 12.3.0. It checks the preserved raw input hashes before writing.

## Engine reproduction

Fetch `refs/pull/441/head` before checking out evidence revision
`d3277791d02e55d7885b276cc67e8aa73e9479e1` from a fresh clone. Use a fresh checkout so its output
cannot overwrite retained evidence. Run `./tools/check.sh`, then:

```sh
"${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}" --path . --resolution 1280x720 \
  --disable-vsync scenes/dev/roof_scale_preview.tscn -- --no-save
```

The scene exits after writing `roof-scale.png`. Still SHA-256:
`61c20215d4ef23de488d76f54e1bb1366377af67f3ee229addde3e1b315f25c1`.
Capture Building source SHA-256:
`be259a8f3af4382c8e018e95d3dfd10a01dc8767bbc78a70730a758264b23948`.
The committed source changes only its footprint comment from that capture's source.
