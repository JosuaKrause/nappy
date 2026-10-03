# Build the requested scene through the standard components

**Proposed, not asked for:** use a versioned JSON recipe, parsed into validated data that
headless tests and the live game consume through the same builder. Keep construction separate
from launching a window or recording a movie. Document the schema and provide actionable
errors that identify the recipe field and the conflicting requirement. Unknown keys,
unknown catalogue identifiers, missing references, invalid coordinates, duplicate object
names, and unsupported versions fail before a run starts.

Let a recipe pin the city choices that matter to the scene: street hierarchy and junctions,
block or lot purposes and layouts, calm-zone footprints, home/start location, closures,
and building or scenery choices needed for the composition. Use the normal lattice,
lot builders, tile painting, building data, and rendering components. Expose construction
inputs at the stage that owns the choice; do not generate a random city and then patch
tiles while leaving navigation, lot metadata, doors, regions, or collision data stale.
Share the construction logic with ordinary generation rather than creating a second city
renderer or a second definition of a street. Recipe use is explicit developer/test setup;
ordinary play keeps its current generation and contracts.

Support exact values and named anchors so a setup can refer to, for example, the west
sidewalk of its named junction or the doorway of its named building. Define coordinate
units and direction conventions once. Resolve every reference deterministically and
report the resolved placements. A requested placement is never replaced with the nearest
available placement without the recipe explicitly asking for that choice.

Unspecified choices can use a recipe's seed, with independent deterministic streams for
unrelated choices. Required choices take precedence over random filling. The builder
must construct the requested arrangement directly; looping through whole-city seeds until
one happens to fit does not fulfill this request. A conflicting or unsupported requirement
fails clearly, without relaxing it or returning the last unsuccessful candidate.

Validate geometry and scene requirements before exposing the completed scene. Preserve
the standard city's reachability and placement checks, and report which requirement
cannot coexist with them. The test cases are unusual valid combinations of standard
components, including a building adjoining the power station. This work needs no
invalid-state mode or bypass of gameplay guarantees. A smaller isolated fixture must
declare its validation scope rather than accidentally passing full-city checks.

Guarantees describe inspectable facts, such as an open crossing, a specified actor at a
specified location, or a required route. They are not a claim that arbitrary combinations
are satisfiable. Document supported fields and constraints; an unsupported request is
reported as such rather than treated as successfully guaranteed.
