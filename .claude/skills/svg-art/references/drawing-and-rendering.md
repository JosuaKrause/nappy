# Drawing an SVG family and rendering it

Read this before drawing or revising an SVG and before rendering one for review: how a family is
drawn so its views and states agree, and how a source preview is made with the game's own parser.

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

Compare a character's state variants as one family: each parent carrying the baby must be
recognizably the same person pushing the stroller, preserving clothing and proportions across
every facing. Keep shared head geometry consistent between gait frames. Trace each leg
continuously from hip to shoe instead of using a color swap as an opposite step (see the
illustrated-png skill's [walking-frame correction toolbox](../../illustrated-png/references/leg-contact-corrections.md)
for donor selection and diagonal-contact anatomy). Review the whole facing/frame/state matrix
together. PNG transfer is on hold (`SKILL.md`); what a transfer asks of a reviewed matrix, shared
generation grids and matching existing derivatives, is the illustrated-png skill's.

Use contact shadows beneath individual objects. A scene containing empty roadway should not
inherit one full-width ellipse across its people, cars and gaps. Check whether runtime code adds
a shadow or redraws the body for a halo before baking one into the texture.

**Separate partial motion from its stationary picture.** When only part of a sprite changes, the
static owner omits those moving pixels and retains the stationary scene while a separate registered
sprite or layer animates the moving part. A composed city block stays a still drawing. Static
layers may overlap the moving crop to supply background revealed between phases or foreground
occlusion in front of it; remove duplicate moving pixels rather than cutting holes in unchanged
art. Compare every recomposed phase with the complete sources and preserve painter order. A moving
part's bounding box does not prove that all static pixels inside it belong to the animation.

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
`docs/evidence/male-player-2026-09-19/render-sources.gd` is a committed instance of this script;
run it with `--help` for its exact usage. An agent's sparse worktree leaves `docs/evidence/` out, so
there `git show HEAD:docs/evidence/male-player-2026-09-19/render-sources.gd` reads it.

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
