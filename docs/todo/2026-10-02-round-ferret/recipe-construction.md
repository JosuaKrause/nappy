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

Validate geometry and scene requirements before exposing the completed scene. A normal
scene must be an arrangement that could actually occur under the game's current
generation and placement rules. Sharing assets, rendering successfully, and satisfying
reachability alone do not establish that. Forced choices must be accepted where the
ordinary generator or planner would make those choices: permitted lot combinations,
special-building adjacency, day/progression eligibility, event placement and actor state
all matter within the authored scope. Reuse those predicates and construction stages so the builder cannot drift
into a second, more permissive definition of a possible city. Report the checks and
accepted choices that establish this claim; do not claim that a seed producing the exact
whole scene has been found when none has. Requested temporal moments also need the
ordinary simulation checks described in runtime-and-replay.md.

The player's primary test cases are unusual valid combinations of standard components,
including a building adjoining the power station. A normal scene may be bounded to its
planned extent, as the player explicitly allows. Validate its authored components and
relationships against the conditions under which they can occur in ordinary generation.
Include required context in the recipe or construction data when a local decision depends
on it; an omitted dependency is not evidence of validity. A bounded scene can receive a
normal-scene result for that declared extent without constructing the surrounding city.
The default-texture exterior is an authoring convenience, not a claim about generated
city ground. Do not apply whole-city reachability or whole-day objective guarantees to
an intentionally unbuilt exterior. Conversely, a recipe claiming a complete city must
pass those full-city checks. Record extent and validation scope with the result so local
validity never silently becomes a claim about an entire run.

**Proposed, not asked for:** distinguish normal scenes, the default, from explicit
test-only fixtures. A fixture that deliberately violates a gameplay rule names each
permitted violation and its expected diagnostic. There is no blanket "skip validation"
switch: malformed recipes, broken references, and every undeclared violation still fail.
An expected violation that does not occur also fails, so the test cannot silently stop
exercising its intended case. Return a distinct fixture classification and the violations
with its result; it must never receive the normal-scene validity result. The player allows
this capability conditionally on preventing accidental invalid scenes; these mechanics
are the proposed way to meet that condition. Trailer recipes require the normal result.

Guarantees describe inspectable facts, such as an open crossing, a specified actor at a
specified location, or a required route. They are not a claim that arbitrary combinations
are satisfiable. Document supported fields and constraints; an unsupported request is
reported as such rather than treated as successfully guaranteed.
