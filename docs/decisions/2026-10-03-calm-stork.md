# calm-stork — Authored trailer scenes with explicit existing objects · 2026-10-03

**Sources.** [PLAYTEST-139](../playtests/PLAYTEST-139.md) describes the trailer's
actions; [brisk-ibis](../playtests/2026-10-02-brisk-ibis.md) asks for those scenes
alongside the power-station examples. [Gentle-marten](../playtests/2026-10-03-gentle-marten.md)
requests screenshots, ordinary or scripted controls, and adjustable pre-roll.
[Rosy-lark](../playtests/2026-10-03-rosy-lark.md) adds activity and composition feedback;
[downy-egret](../playtests/2026-10-03-downy-egret.md) supplies the numbered review.
[Spry-hawk](../playtests/2026-10-03-spry-hawk.md) confirms moving the restaurant guests
east. [Dappled-lynx](../playtests/2026-10-03-dappled-lynx.md) explicitly rejects automatic
event selection and requires existing game objects, including the standard vertical gate.
[Amber-wombat](../playtests/2026-10-03-amber-wombat.md) reiterates keeping all work in
#457. The obsolete extraction PRs #458 and #460 are closed without merging.

**Authored content.** The saved recipes install selected production events, seals,
closures and region gates, without scheduler or director fill, in both free and scripted
play. The earlier interpretation of bustle as permission to run normal event selection
was wrong. Crowd and traffic simulation remain independent of event selection. Ordinary
game population, event budgets and automatic scheduling remain unchanged.

Recipe controls select existing café pairs, gate segments, roadblock mouths and roof
fixtures. The restaurant guests are a SealPlanner café pair, not a catalogue event;
the unwanted water-main break also came from seal selection. The guests move one
448px block east, from x2128 to x2576. The wrong-turn action retains its intended
approach, turnaround and alternate route. At the revised capture there are 32 visible
walkers, 21 left and 11 right, with an inhabited right sidewalk.

The early scenes use residential, industrial, skylight-roof and park-side compositions.
Existing roof fixtures are placed explicitly by production roof lot and interior cell;
invalid kinds, edge cells, overlaps, unavailable district fixtures and duplicate roofs
fail. Omitted roofs retain their ordinary furniture, and streaming restores pinned
fixtures. No artwork or gameplay object type is added.

The father approaches horizontally toward the standard vertical checkpoint, including
its real huts, guards and traffic-operated boom. The dog scene selects only the charging
dog and contains no water-main break. The chase uses the actual finale controller,
carrying state and pursuing guards. Its capture records carrying speed 168px/s at the
existing animation's contact stride; the still establishes pose, while movement and
pursuit observations establish action. Walking and running share the production carrying
pictures with different cadence. The final scene zooms from her doorstep to the whole
active city, with moving walkers and cars checked in every quadrant.

The truck scene uses the actual day-13 three-truck formation, with the mother facing
south and varied posters on both buildings. The existing roadblock moves from the
bottom to the west mouth of the left street, x1552, replacing the earlier bollards with
a vertical band. A first revision at the east mouth, x1776, did not match the pictured
left entrance and was corrected before the final still.

Explicit placements reuse existing eligibility and geometry checks. Escape recipes
reject unsupported ordinary seals, gates, barriers and closures rather than accepting
pins they cannot install. Bounded scenes require an entire selected structure's street
segment; overlapping seal, closure and barrier choices fail. Fallen-tree placement
refreshes the rendered tree state as well as the collision/event state. Accepted
power-station hall and yard pictures and geometry are preserved.

**Evidence and limits.** [The evidence README](../evidence/calm-stork-scene-stills-2026-10-03/README.md)
names the source for each still and its action/capture manifests. The player expressly
requests stills for these motion scenes, so headless named-tick observations accompany
them. Relevant stills and manifests are retained; whole telemetry folders and unrelated
automatic pictures are excluded under the player's
[compact-evidence instruction](https://github.com/JosuaKrause/nappy/blob/336970864090bfcb7b360a2486c5f85e1788924e/docs/playtests/2026-10-03-busy-wombat.md).
No video is rendered, and still/action verification makes no pixel-reproducibility claim.

**Initial presentation choices.** The blower as an early encounter, the four early
building/roof arrangements, the preview parent assignments outside the three prescribed
glimpses, and the whole-city population at ordinary area density were presented for
review. The first authored cut split early danger into blower and dog, changed durations
and omitted draft caption overlays; those proposals did not constitute editorial approval.
[M204, the trailer cut](../todo/2026-09-25-M204/README.md) retains the three drafted
caption phrases, final ordering, title/fades, thirty-second limit, resolution/audio,
movie action checks and loaded-render reproducibility. It also retains the separate
standalone escape screenshot-path report; the working recipe path does not close it.

**Verification.** The affected headless run passes 2,051 checks with no failures.
Expanded construction checks pass 51 at source 9768f6de; boot and the 289-check CLI
suite pass. Six updated scene manifests have complete playback and no failed
observations; composition is independently inspected from their PNGs. Runtime seed
variation and construction-context variation are separate: the latter holds an explicit
lot/layout fixed across contexts 1917501 and 61400 while unpinned construction changes.
Pins made ineligible by a different context are rejected, not silently moved or found
through seed hunting. Roof-coverage assertions require actual nonempty covered columns.
Caller-relative recipe paths are normalized before changing directory, and malformed
JSON/capture failures identify their recipe or diagnostic log. Full-game verification
remains CI's; no local full-game or movie-render campaign is used.

## Bird flock, park walk and evenly busy streets · 2026-10-03

[Lilac-beaver](../playtests/2026-10-03-lilac-beaver.md) accepts scenes 7–10 and requests
four changes: a bird flock in scene 4, the tree across the road in scene 5, walking
inside the park near a visible road in scene 6, and equally high pedestrian density
away from the main road in scenes 3–5. [Tiny-dolphin](../playtests/2026-10-03-tiny-dolphin.md)
clarifies that the compositions need not all contain a main road, particularly when
side streets help balance the pedestrians.

`trailer-birds.json` replaces `trailer-blower.json` and selects the existing
`pigeon_flock`; shot and CLI references follow the rename. Scene 5 moves the real
tree and its pit from tile [50,74] to [50,71], across the same road by 96 world pixels.
The construction-stage `city.tree_moves` pins feed the shared tree placement data
used by planning, props and collision. Invalid sources, occupied or invalid opposite
curbs, home-door conflicts and duplicate destinations fail. Scene 6 starts inside
the park at [1296,1712] and walks south near its east edge, with the road in view.

The original pedestrian distribution uses the main-road busyness weight 5 against
ordinary corridor weights 0.5–1.7. Scenes 3–5 opt into equal corridor weights and a
2× pedestrian multiplier: 400 walkers over the moving field instead of the ordinary
act-1 count of 200. These values are scene presentation choices open to correction,
not changes to ordinary game density. The override applies on recycling as well as
initial placement and resets when an ordinary day starts. Cars retain their counts
and weighting, and pedestrians retain production movement and collision behavior.

The first revised choice capture measures 35 visible walkers: 12 on the horizontal
street, 9 on the main road and 14 on the other vertical street; 20 are right of the
player and 15 left. Its scripted wrong-turn/backtrack still passes, with the higher
crowd's real excitement cost retained. These are capture measurements, not a claim
that exact counts remain constant during play.

Uniform random corridor weights alone left the dog's first revised capture with only
two walkers on one side street against thirteen on the main road. Recipe-only initial
placement therefore samples eligible production sidewalk lanes evenly, validating each
position with the existing `setup_at` path, while walkers keep moving and recycle with
the uniform distribution. The bird composition moves one block east onto ordinary side
streets using an explicit industrial lot and its actual production roof footprint;
the map's main road is not reclassified or removed.

Review found that fixed lane-direction parity imposed a new walking convention and
that an oversized population request could be silently truncated. The final source,
`1f0823ed`, uses varied seeded headings and refuses an overcapacity request before
play begins. Neither change alters ordinary population or pedestrian behavior.

The revised captures contain 40 visible walkers in choice (17 horizontal, 10 main road,
13 side street), 36 in birds (15 horizontal, 11 and 10 on the vertical side streets),
and 34 in dog (13 horizontal, 7 side street, 14 main road). All but one choice walker
are moving at the capture tick. Street lengths and visible portions differ, so these
measurements alone do not establish equally high density. Review measured essentially
equal visible lengths and sidewalk widths in the dog scene and found its left street
still too sparse; that composition remains open for correction.
The accepted recipes and images for scenes 1–2 and 7–10 remain byte-identical.

The affected headless run passed 25,081 checks before the final heading/capacity
correction; its 14 focused checks then passed, as did all three final scripted action
manifests. The 289-check CLI suite, boot check, lint and whitespace checks passed.
The final evidence commit is `e9c24e07`; the README identifies each capture's runtime
source rather than treating the evidence commit as its source. M204 retains the
separate movie/editorial work.

**Main integration.** Before the final dog correction, the branch at `8b0e2fbe`
integrates main `8a5228ee`, with base `746e7b3f`. Main adds storage cleanup,
compact-evidence rules, CI helpers and independently named review records; it changes
no gameplay source, test or recipe from that base. The only shared edited file is the
tool catalogue: its scene runner entry remains beside main's sparse-validation and
cleanup entries. Main's evidence removals do not touch these scene captures. All
independent queue, playtest and decision files retain their identities. The merge
needs no textual resolution; boot, lint and whitespace checks verify the result.
