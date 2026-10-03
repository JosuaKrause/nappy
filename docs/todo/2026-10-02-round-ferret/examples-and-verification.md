# Demonstrate edge cases and a composed trailer shot

Ship a recipe that directly constructs the player's example: a building adjoining the
power station so the roof/facade join is exercised without searching seeds. The existing
M203 rule keeps a facade wherever no roof extension actually covers it. Exercise the
hall and fenced-yard cases with the real city building components, checking coverage
and showing that the join leaves no blank tiles. The player names the joined-building
case; the hall/yard variants are proposed coverage of the recorded special handling.

**Proposed, not asked for:** add recipes demonstrating a constrained crossing with named
traffic actors, a precisely placed pursuit with a scripted player path, and a truck
passing beside the player in the camera. These are tool examples; they do not choose or
approve the final trailer cut. Include rerun commands for a headless check, interactive
exploration, a still or burst, and recording through the existing tools.

Test the public recipe-loading and construction path against conflicting requirements,
malformed files, unknown fields and IDs, unresolved anchors, and illegal placements.
Assert on the built map and live actor state, not only on the parsed recipe or a mocked
builder. Demonstrate that requested geometry and placements stay fixed when an unrelated
background seed changes, and that the builder does not enumerate whole-city seeds to
find those requirements. Verify relevant navigation and collision metadata agree with
the rendered components.

Repeat a headless scripted scene and compare the required state at named ticks. Exercise
the live startup path as well: prove the ordinary scheduler cannot replace required actors,
recipe errors exit unsuccessfully, and recipe runs do not write player progress. Cover the
no-recipe path with the affected existing city, event, crowd, and rig suites so adding
control inputs does not silently change normal generation.

Render the trailer example twice through the recording tool under matched settings and
check the frames using the existing repeated-render machinery. Check the scene with
background load as well as in an otherwise idle run: the trailer's open reproducibility
problem includes load. Keep compact hashes, setup manifests, rerun instructions and results
as evidence, not checked-in videos. A failed repeated render remains a failure to resolve
within this work, rather than a claim of determinism supported only by a matching map.

Show an early still for composition and a short burst for motion before polishing the
examples. Use the existing rules for retained capture evidence and commit-pinned visual
links in the PR. The player judges whether composing and revising a recipe gives the
scene they intend; file that authoring/visual review with the implementation. Headless
success proves the specified state and behavior, not that the shot looks right.
