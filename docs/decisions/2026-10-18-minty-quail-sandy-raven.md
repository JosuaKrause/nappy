# minty-quail — Roofs draw through a drawer the city hands in, and the roof suites test placement and drawing apart (tests through public seams: W5a) · 2026-11-04

minty-quail's `tests-public-seams.md`: the design pilot for drawn art, from the player's answer to
the board question drawn-art-tests (inbox #1018): where the elements go is decided by the random
draws and tested on its own, the general drawing code is tested elsewhere, and the holder is tested
with a mock drawer injected that confirms every element is drawn. The roof art first; the event
pictures follow on the same shape.

**Built.**
- `Building.roof_layout()` is a pure query: one entry per roof unit, farthest first (the cell, the
  cells and span it covers, its kind and texture, and a duct section's links), rolled from the
  building's variant and place, or taken from an authored recipe, and writing nothing. Its caller is
  the building's own drawing, which caches it and draws the cache.
- `RoofDrawer` (`src/city/roof_drawer.gd`) has one call, `draw()`, that stands a roof unit in a layer
  exactly as the building did before, its rotor included. `City._spawn_buildings()` builds one over
  its atlas and hands it to every building through `Building.roof_drawer`; a building nobody handed
  one (the preview rigs) makes its own as it does its atlas.
- `tests/recording_roof_drawer.gd` extends it and records every unit it is told to draw, so a test
  compares what was drawn with what was placed, the rotor's frame included, against the scenery clock
  the city hands the building. The real drawer is tested on its own, handed a bare layer and told to
  draw a vent on either rotor frame, a duct and a plain unit. A narrow roof is checked to lay out as
  many units as a wide one with the same interior, instead of rebuilding the count from the private
  density. `test_roof_entities.gd` (private-read lines 17 to 0) and `test_recipe_roofs.gd` (8 to 0)
  read no private member or constant. Checks 2212 and 67 to 2722 and 68; twenty-nine mutation runs.
- Before and after stills of a roofed stretch differ only by encoder noise
  (`docs/evidence/roof-drawer-2026-11-04/`).

**Open to overturn:** the drawer works per element, one call per roof unit, rather than wrapping the
general drawing calls, since the general drawing code is tested elsewhere (inbox #1018); the event
pictures follow it at that level. The layer goes in with each call, so one drawer serves the city and
the preview rigs unchanged. The layout keeps the private kind beside the texture, since the cache and
the vent clock use it.

**Not done:** `test_scenery_residency.gd`, `test_scenery_animation.gd` and the scenery animation
probe still read the roof objects and rotor layers; they follow this shape, with the rotor's frame
read off the layer or carried by the drawer.
