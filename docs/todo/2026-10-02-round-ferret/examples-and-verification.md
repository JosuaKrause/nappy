# Demonstrate edge cases and a composed trailer shot

Ship a recipe that directly constructs the player's example: a building adjoining the
power station so the roof/facade join is exercised without searching seeds. The existing
M203 rule keeps a facade wherever no roof extension actually covers it. Exercise the
hall and fenced-yard cases with the real city building components, checking coverage
and showing that the join leaves no blank tiles. The player names the joined-building
case; the hall/yard variants are proposed coverage of the recorded special handling.

Ship the scenes in [trailer recipes](trailer-recipes.md) as required by the player's
additional instruction. Those shots supplement the power-plant join test and are not
optional generic examples. Include rerun commands for a headless check, interactive
exploration, a still or burst, and recording through the existing tools.

**Proposed, not asked for:** a constrained crossing with named traffic actors can provide
an additional compact traffic fixture. It does not replace a required trailer scene.

Test the public recipe-loading and construction path against conflicting requirements,
malformed files, unknown fields and IDs, unresolved anchors, and illegal placements.
Assert on the built map and live actor state, not only on the parsed recipe or a mocked
builder. Demonstrate that requested geometry and placements stay fixed when an unrelated
background seed changes, and that the builder does not enumerate whole-city seeds to
find those requirements. Verify relevant navigation and collision metadata agree with
the rendered components.

Prove the possible-gameplay guarantee, not just the drawing: a configuration that uses
real components but violates a normal generator or planner rule is refused by default.
The building/power-station examples pass those same rules. Exercise explicit invalid
fixtures separately: only named expected violations are accepted, additional violations
fail, a missing expected violation fails, and the result is never classified as a normal
scene. Verify that the trailer entry point refuses a deliberately invalid test fixture
and accepts a bounded normal scene only with the applicable generation checks and
declared extent. A local result must not claim full-city guarantees. These checks enforce
the player's condition on supporting invalid fixtures and their bounded-scene allowance.

Launch the power-plant join and every required trailer recipe in both free play and
scripted modes. Compare their initial authored layout and actor state, prove the script
does not move the player or camera in free play, and exercise ordinary input instead.
Walk across the authored bounds and back: the exterior shows the default texture,
there is no invisible wall or automatic return, and re-entry keeps the ongoing scene
state. Restarting the recipe resets it to the saved setup. Bounds must not clip actors
or scenery needed during a scripted shot, particularly the full-city zoom.

Repeat a headless scripted scene and compare the required state at named ticks. Exercise
the live startup path as well: prove the ordinary scheduler cannot replace required actors,
recipe errors exit unsuccessfully, and recipe runs do not write player progress. Cover the
no-recipe path with the affected existing city, event, crowd, and rig suites so adding
control inputs does not silently change normal generation.

Render every required trailer scene twice through the recording tool under matched settings and
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
