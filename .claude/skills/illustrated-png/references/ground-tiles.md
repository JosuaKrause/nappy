# Ground tiles

For opaque ground tiles, extract fixed atlas cells rather than fitting visible bounding boxes.
Cell edges are part of the texture's placement contract. Generated atlas dimensions need not
divide evenly by the grid: record normalized cells and rounded pixel bounds. Compare opposite
road-line halves assembled as neighbors as well as repeated full tiles; alpha equality alone
cannot reveal shifted markings, unwanted grid borders or a material that changes between variants.
Keep low-contrast ground texture quiet enough for actors and route markings to remain legible.
Rectangular paving needs complete slab joints across tile boundaries as well as inside each tile.
Inspect repeated patches in both axes: center-only seams can merge neighboring rectangles into
larger unintended slabs. Preserve the selected material when completing its boundary joints.

Review street-surface continuity in actual generated map layouts, using `GroundTiles.source_for`
and the runtime TileSet mapping. Include repeated runs, both sidewalk lanes, both street axes and
junction corners. Short isolated neighbor strips do not expose all repeated joints or corner
transitions. Keep diagnostic labels and grid overlays separate from the clean assembled artwork.

Ground variants share their base material. Build sidewalk variants from one paving texture and
road variants from one asphalt texture; use transparent layers for curbstones, red main-street
edges, yellow lines, crosswalks and damage. Remove the ground background from detail artwork
before alpha compositing it over the actual base. Preserve the layer inputs and composition
recipe, including SVG sources for the components. Pixels outside the overlay remain identical
to the base. Damage variations share pools by severity across floor materials; inspect each
stencil over every supported base so extracted slab joints do not become a second floor grid.
Keep final registered paving inputs separate from the original material inputs used to extract
damage. Rebuilding components must retain the reviewed base's boundary joints.
Inspect repeated bases in both axes for lighting gradients and brightness jumps;
a shared texture still needs to tile cleanly. Blend curbstones, markings, damage and grass
features over their bases in the engine, retaining the separate component graphics. The
rotation/offset blend that smooths the asphalt and grass bases is an offline preparation step.
Separate existing grass features from a soft green base and place them sparsely with stable
city-seed variation, keeping grass detail quieter than the actors and route markings.
Validate component IDs and rotations against the authored TileSet and ground selector rather
than inferring their order from filenames. Verify the composed grass atlas itself as well as
its selection logic; a missing component is a `push_error` naming the source and the component,
and that source then draws nothing — a default bake's `ground` page carries no whole authored
tile for a composed source to fall back to. Crop
grass features to their visible bounds before placing them so their clumps remain whole.
