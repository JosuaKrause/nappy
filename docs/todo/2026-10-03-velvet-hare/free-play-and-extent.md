# Explore every saved scene with ordinary controls

The player's requirement is the normal game's behavior: scripted movements, or load
in and control normally. Every recipe shares its initial layout, actors and state
between those uses. Ordinary input and the normal gameplay camera work without a
script controlling either; traffic, events and guards continue their normal updates.
Do not end an experiment at a capture deadline or save it into the player's progress.

**Proposed, not asked for:** choose scripted/free-play behavior at launch, and offer
a restart that restores the recipe's initial state. Separate interactive and scripted
copies of each authored scene are unnecessary.

The player allows a scene to exist only for its planned extent, with default texture
beyond it. Let them walk out and back into the ongoing scene without an invisible
wall, teleport or reset. Preserve normal collisions and consequences inside.
**Proposed, not asked for:** use plain default ground outside without generating
surrounding streets or encounters. That exterior is outside the reported validation
scope and cannot satisfy an authored route guarantee.

[M120, the map edge](../../decisions/2026-09-13-M120-the-map-edge.md) clamps
`City.camera_bounds()` to the painted band, reserving camera look-ahead. Recipes
need a separate camera-bound behavior for the permitted exterior; retain the normal
city clamp and ensure default ground fills the view during walking and look-ahead.
Required actor paths and the whole-city zoom view stay inside constructed content.

Test both uses for the power-station joins and all trailer recipes. Compare initial
setup, prove scripts do not override ordinary controls, cross the extent and return,
and verify the scene continues. If implementing restart, test reset as well. Check
save isolation and that free play has no recording deadline. A bounded scene is not
an invalid fixture solely because its surroundings are unbuilt; explicit existing
creation-check failures still require the builder's explicit allow.
