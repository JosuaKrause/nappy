---
name: svg-art
description: Create, revise and visually review the repository's SVG game graphics, including directional variants, grounding and asset integration. Load before editing SVG assets; raster illustration work uses illustrated-png instead.
---

# SVG artwork

**Every PNG asset has a corresponding SVG asset, and the SVG always comes first.** Author and
review the SVG as the editable source of subject, geometry, pose and placement before applying
the illustrated-png workflow. Preserve it alongside the registered PNG derivative. This applies
to new directional/state variants, UI and identity assets as well as standing game entities.

SVG is the editable source for game graphics. Author vectors directly with patches; use the existing
family as the style reference. Read `docs/GRAPHICS.md` for the asset's actual binding and the
owning milestone in `docs/TODO.md` before designing. Follow `feedback` for player requests and
`verify` for runtime checks; this skill adds the visual work those checks cannot judge.

## Establish the picture's contract

- Inspect the existing SVG **and a rendered image**, alongside nearby actors, props and ground.
  Read the caller: a single sprite, repeated segment, whole-street scene and TileSet tile have
  different registration and scale contracts. Trace indirect `.tres` and scene references too.
- Record the native canvas, intended world footprint, ground anchor, facing convention and
  state variants. Tiles are sized from `Tuning.TILE_SIZE`; a multi-tile decal uses the requested
  footprint rather than scaling a small actor arbitrarily.
- Keep world position, visible bounds and collision distinct. A circular collision diameter
  does not justify stretching an end-view car to fill a square. If the art reveals a collision
  mismatch, document the gameplay question instead of changing physics as an art repair.

## Draw and compare

Start with the silhouette, then major material planes, then sparse details that remain legible
at gameplay scale. Match the family’s muted palette, dark outlines, light direction and detail
density. Sample existing SVG colours and stroke widths; do not impose one width on every scale.
Use transparent margins for decals and actors, but preserve a tile's required ground fill.

The renderer mixes overhead ground with upright actors. Draw a vehicle's side and end views as
separate projections; rotating a side-view picture does not create an end view. Keep people
upright in scenes spanning either road axis. Check how the caller interprets the suffix:
checkpoint gate suffixes name the **road** axis, whereas a scene suffix may name its canvas axis.
For an orientation correction, swap existing bindings when that is all the request requires.

For modular states, preserve the shared canvas and the meaningful fixed point: a gate's hinge,
a person's feet or a hut's ground anchor. Annotate non-default anchors inside the SVG. Ground
decals use their centre; standing sprites usually use bottom centre through `Sprites`.

Use contact shadows beneath individual objects. A scene containing empty roadway should not
inherit one full-width ellipse across its people, cars and gaps. Check whether runtime code adds
a shadow or redraws the body for a halo before baking one into the texture.

Review material recognition rather than detail count: pipes need visible hollow mouths, a skip
needs an open rim, wrecks need readable damage, and craters need uneven broken ground and concave
shading. Regular concentric rims or radial spokes can read as manufactured structures. Choose
details for the particular object rather than treating these examples as mandatory decoration.

## Render with the game's SVG parser

Validate XML separately from rendering. `./tools/lint.sh` checks tracked SVGs; for a newly created
untracked file use `xmllint --noout path/to/file.svg` or pass its path explicitly to the lint tool.
XML comments cannot contain double hyphens. A forgiving Godot import is not XML validation.

Use Godot's `Image.load_svg_from_string()` for a source preview. A small scratch `SceneTree`
script can load each requested SVG at scales 1 and 3 and save PNGs. The essential operations are:

```gdscript
var raster := Image.new()
var result := raster.load_svg_from_string(FileAccess.get_file_as_string(source), scale)
if result != OK:
    push_error("SVG render failed: " + source)
    quit(1)
    return
if raster.save_png(destination) != OK:
    push_error("PNG save failed: " + destination)
    quit(1)
    return
```

Run the scratch script with the installed Godot binary, `--headless --path <imported-project>
--script <scratch-script> -- <inputs>`. Import the actual checkout with `./tools/check.sh` first;
an unimported worktree can fail on unrelated autoload types before the renderer runs. A minimal
scratch project without game autoloads is another option. Do not wait for a failed script to quit
if an error prevents its normal exit; inspect the output and stop that process.

**Open and inspect the saved images.** A successful command only proves that a file was written.
Review native size for recognition, enlargement for malformed joins and clipping, and a neutral
or representative ground background for transparency. Contact sheets help compare families;
label fitted cells as fitted, since they do not establish shared world scale. Render every
changed directional/state variant from its current SVG, not an earlier cached PNG.

For an existing runtime binding, take the smallest useful gameplay capture through `verify`:
choose a reproducible seed, day, location and normal camera scale that actually exposes the object.
Check both axes when direction matters. Prepared unbound assets need source previews, not invented
runtime behavior just to photograph them. Iterate on visible defects, rerender the changed parts,
and preserve the final evidence through `session-captures` where it is a gameplay run.

## Integrate and leave the inventory accurate

Keep game asset `.import` sidecars with their SVGs; `.godot/` is rebuildable cache. Evidence under
`docs/` has no sidecars because `docs/.gdignore` excludes it. Check both revisions if GitHub's
image-diff viewer fails: malformed XML in the old side can break the comparison while the new
file is valid. Link a current rendered preview rather than repeatedly altering valid artwork.

Update `docs/GRAPHICS.md` with file paths, registration and actual current use. A prepared asset
stays unbound in the catalogue until code or a resource uses it. In graphics-dependent milestones,
name the files and intended states to reuse without closing outstanding gameplay decisions.
Keep drafts rejected only internally by an assistant outside the repository. Preserve artwork
rejected by a human or suggested for human review, with the review outcome in
`docs/DECISIONS.md`; preserve the player's words in the playtest record. PR image links use a
commit containing the image, as `committing` requires.

Run import/boot and XML/doc lint. Add focused tests only for behavior a picture cannot verify,
such as axis selection or grounding. Test the drawing path the runtime actually takes; do not
re-derive repetition arithmetic for a whole-scene renderer that never repeats a texture.

Commit each finished image promptly after visual review and validation, with its `.import`
sidecar. Do not wait for the whole family. Keep inseparable body/trim layers together so a
commit still contains a reviewable image.
