priority: next

# round-ferret — Build exact scenes and the power-station join from saved recipes · filed 2026-10-02

The player wants standard city components with guaranteed requested outcomes, so edge
cases need no seed hunting. They choose **saved recipes first**;
[gray-otter, scene-builder request](../../playtests/2026-10-02-gray-otter.md)
holds the authoring question. A visual editor remains open for later, without being
part of this work. [minty-wombat, valid component joins](../../playtests/2026-10-02-minty-wombat.md)
names the building adjoining the power station and the special handling that avoids
blank tiles. [frosty-finch, explicit fixtures](../../playtests/2026-10-02-frosty-finch.md)
permits invalid test fixtures only if they cannot accidentally become normal scenes.

The player's clarification in [gentle-marten, scene-builder review and scope](../../playtests/2026-10-03-gentle-marten.md)
limits validation to checks city creation already explicitly performs: refuse a failed
check unless explicitly allowed for a test or edge case. Where no easy check exists,
no new proof is required. Do not claim universal realizability or invent a seed search.

This slice contains [construction](recipe-construction.md), a minimal
[live setup and replay seam](runtime-and-replay.md), and
[power-station examples and tests](examples-and-verification.md).
It can ship independently of the trailer and interactive extent slices. The player
requests implementation in a new PR on top of the design PR.

The linked work remains required:
[calm-stork, described trailer scenes and screenshots](../2026-10-03-calm-stork/README.md)
follows this builder;
[velvet-hare, ordinary controls and bounded ground](../2026-10-03-velvet-hare/README.md)
follows those scenes and applies to every recipe. The chain follows the review's
requested split. **Proposed, not asked for:** the `next` band and incremental delivery
order; all three slices remain part of the user's implementation request.

**Proposed, not asked for:** versioned JSON, named anchors, independent deterministic
seed streams, progression/meter controls and a documented ambient default provide a
shared authoring surface instead of bespoke scripts. Named expected violations and
trailer fixture refusal are proposed safeguards beyond the requested explicit allow.

[M204, the trailer cut](../2026-09-25-M204/README.md) retains movie assembly, captions,
editorial approval and its existing recording/reproducibility bugs. Load-reproducible
movie output is not a completion criterion for the builder or scene screenshots.
