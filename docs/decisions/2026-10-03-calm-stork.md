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

**Choices open to overturn.** The blower as an early encounter, the four early
building/roof arrangements, the preview parent assignments outside the three prescribed
glimpses, and the whole-city population at ordinary area density are presentation choices
for review. The current trailer cut splits early danger into blower and dog, changes
durations and omits draft caption overlays; those are proposals, not editorial approval.
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
