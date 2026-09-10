# Environment SVG source review

This folder contains the reviewed source artwork for M103, the drawings the queue owes.
[sources.csv](sources.csv) lists the native canvas, anchor convention, alpha bounds and usage of
every source. The set contains 81 new SVGs and the revised existing industrial vent source.
Every game source has its import sidecar. New sources remain prepared until their owning
milestone adds the caller or resource entry.

The contact sheets show each source at native size and 3× using Godot's SVG parser. Images keep
their authored dimensions; they are not fitted to a common object size. Labels use a readable
font over an opaque neutral background. The background is presentation, not part of an asset.

- [Interior sources](interior-review.png): floors, all four cardinal floor edges, walls, doors,
  stairs, chandelier, puddle and furniture barricade.
- [Props](props-review.png): chalk, small litter, sacks, vent phases, roof furniture and tree pit.
- [Frontages and windows](buildings-review.png): four shops in plain, sloped-awning and shuttered
  states, plus tall and shuttered window pairs.
- [Fire escapes](fire-escapes-review.png) and [wall comparison](fire-escape-wall-review.png):
  both transparent overlays over two rows of wall and window cells.
- [Ground degradation](degradation-review.png) and [tile repetition](tile-repetition-review.png):
  two patterns at each of three damage levels for road, sidewalk and alley.
- [Interior floor repetition](floor-repetition-review.png): hallway, basement and stairwell.
- [Event options](events-review.png): steam and the optional explosion picture.
- [Chalk on pavement](chalk-ground-review.png): the circle/cross source and the same mark with
  the small acknowledgement tick.

The tile-repetition comparison includes the existing roof, existing alley and the prepared
alley alternative. The roof uses Palette's first building-roof tint, #c2a179, because its
near-white source is tinted in the live renderer. The fire-escape comparison uses the matching
shaded wall tint and untinted dark windows. These are source composites, not gameplay captures.

## Prepared inventory

- Interior floors and edges: `assets/interior/hallway_floor.svg`,
  `hallway_floor_edge_{n,e,s,w}.svg`, `basement_floor.svg`,
  `basement_floor_edge_{n,e,s,w}.svg`, and `stairwell_floor.svg`.
- Interior walls and access: `hallway_wall.svg`, `hallway_wall_window.svg`,
  `hallway_wall_window_flash.svg`, `basement_wall_brick.svg`, `stair_down.svg`,
  `stairwell_door.svg`, `entrance_door.svg`, `emergency_exit_door.svg` and
  `lift_door_dead.svg`.
- Interior props: `entrance_barricade.svg`, `chandelier.svg` and `puddle.svg`.
- Event options: `assets/events/steam.svg` and `explosion_preview.svg`.
- Ground sources: `assets/tiles/alley_draft.svg`, plus
  `{road,sidewalk,alley}_cracked_{hairline,cracked,broken}_{a,b}.svg`.
- Degradation props: `assets/props/litter_{apple,newspaper,cup,bag,can}.svg`,
  `garbage_sack.svg`, `garbage_sacks_pile.svg` and `tree_pit.svg`.
- Roof props: `industrial_vent.svg` and `industrial_vent_b.svg`;
  `roof_hvac_unit.svg`, `roof_hvac_unit_b.svg`, `roof_duct_straight.svg`,
  `roof_duct_corner.svg`, `roof_skylight.svg`, `roof_skylight_b.svg`,
  `roof_vent_stack.svg` and `roof_water_tank.svg`.
- Frontages: `assets/buildings/storefront_{a,b,c,d}.svg`,
  `storefront_{a,b,c,d}_awning.svg`, `storefront_{a,b,c,d}_shuttered.svg`,
  `fire_escape_{a,b}.svg`, `window_tall_{dark,lit}.svg` and
  `window_shuttered_{dark,lit}.svg`.
- Resistance sources: `assets/props/chalk_mark.svg` and `chalk_mark_touched.svg`.

The mouse and riot-van end source belong to the separately reviewed vehicle/animal source set.

## Canvas and registration

Floor and wall modules are 32×32. Damage tiles preserve the matching base fill and paving or
drainage seams; cracks and cuts stay inside their tile. The hallway south edge includes door
thresholds because hallway doors lie below the view. Other cardinal edges provide wall-side trim.
The alley alternative tiles beside its own neighbours and leaves the live alley source intact.

Ground decals use the canvas centre: puddle, tree pit, litter and chalk. Every litter source
uses a 32×32 transparent canvas and visible geometry at most ten native pixels wide or high,
including antialiasing. The apple is an eaten core; the cup lies on its side and the bag lies
collapsed. None has an upright contact shadow.

Standing props use bottom-centre registration. Doors are 24×42 for the emergency exit, 28×40
for the stairwell, 42×44 for the entrance and 34×42 for the lift. The chandelier and its light
pool share a 32×48 source; steam is 32×48. The 48×30 entrance barricade keeps distinct wardrobe,
mattress and chair silhouettes. A sack is 28×34 and the three-sack pile is 42×34.

Roof units use 32×32 canvases, except the 64×32 straight duct and 32×48 water tank. The enclosed
elbow and straight duct share 12px wall height and matching projected entrance sections.
The tank's open legs and braces remain visible. The industrial vent retains its original
housing, cap and seams; the service fan alternates cross and diagonal phases. The phase choice
is a visible eighth-turn for its symmetric four-spoke rotor. Animation is not bound.

Each storefront is 32×32 and keeps its doorway at x3..12 with its bottom at y31. The awning
obscures the doorway's upper edge and slopes forward from its wall mounts to an overhanging
valance, with a dark underside. Shutter states preserve that door position. Both 48×64 fire
escapes remain transparent around the metalwork,
so the facade and windows can show through. Window sources remain 32×32 overlays.

The chalk sources preserve the code-drawn circle and crossing strokes. The touched source adds
a small tick at the upper-right as the acknowledgement that she has seen the mark. The current
ContactPoint drawing is unchanged.

## Verification and remaining bindings

Every source is XML-valid and rendered through Godot Image.load_svg_from_string at 1× and 3×.
The sheets include native-scale recognition, enlarged joins and clipping, tile repetition,
facade state alignment, vent phases and the chalk comparison. Repository import/boot and
documentation lint pass. No full local gameplay suite is needed for these artwork-only sources.

The existing callers and resources remain unchanged: Building, City, the ground TileSet,
ContactPoint and EventInstance. The existing industrial vent source contains frame A; the
second frame is prepared. The optional explosion stays unbound until the finale chooses its
presentation. The alley alternative stays beside the current alley until the played verdict
chooses it. No runtime behavior is added to demonstrate a prepared picture.
