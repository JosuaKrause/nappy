# Build pinned choices through standard city components

**Proposed, not asked for:** versioned JSON parsed by a shared builder, with actionable
field errors. Reject malformed data, unsupported versions/fields, unknown IDs, duplicate
names and broken references. Define supported coordinates and units. Named anchors and
independent deterministic streams for unspecified choices are proposed conveniences.

Pin supported streets, blocks, special-building layouts and scene placements before
derived geometry, navigation, collision and visible components are built. Share the
ordinary construction stages. Do not patch a finished random map or search whole-city
seeds for an arrangement. Unsupported or contradictory requirements fail explicitly;
a requested object is never silently replaced by a nearby one. Document supported pins.

Reuse the checks city creation already explicitly runs. Their failures require an
explicit allow for tests and edge cases. Where no easy check exists, no additional
realizability proof is required. Report which checks ran and their scope; passing them
does not establish that a seed for the exact scene exists. Ordinary no-recipe generation
keeps its existing contracts. A bounded scene's unbuilt surroundings do not count as a
full-city route or objective guarantee.

**Proposed, not asked for:** fixtures name expected violations and retain distinct
classification through loading and replay. Undeclared violations, missing expected
violations, malformed input and broken references still fail. Trailer entry points
refuse fixtures. These mechanics implement the player's requested explicit allow while
guarding against accidentally authoring an invalid normal scene.
