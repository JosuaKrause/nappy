# silky-rabbit — Nearby ground regions prepare across frames · 2026-10-02

The player asks in [issue 446](https://github.com/JosuaKrause/nappy/issues/446) to spread
ground composition over multiple frames to improve stuttering. They direct recording a new
todo and starting it, then correct the target: composition already happens dynamically around
the player, and distant regions unload. Their complete issue and correction are in
[speckled-marten, spread ground compositing across frames](../playtests/2026-10-02-speckled-marten.md).
They subsequently request measuring before and after, and testing a stricter one-section-per-frame
rule, in [gentle-moose, compare ground preparation before and after](../playtests/2026-10-02-gentle-moose.md).
The entry is filed and completed within the same PR; no pre-existing main queue entry is removed.

**What is built.** An existing 8×8-cell nearby region advances through four 4×4-cell renderer
quadrants. Ordinary preparation advances at most one quadrant per region per process frame;
distinct approaching regions share the unchanged 2,000µs soft CPU budget. The frame fence
belongs to residency, so canceling and rebuilding a job cannot advance that region again
within the same frame. `TileMapLayer.update_internals()` includes renderer-command creation
within the step timer. The budget remains soft: a begun step finishes.

Pending ground is held separately from complete resident regions. Its layers are visible
in-tree at their actual off-screen coordinates because Godot's renderer discards hidden-layer
work. Only completed regions count as resident. Work pauses outside the loading boundary,
survives reversals within the wider retention boundary, and is discarded beyond it. Live
cell edits, route-tint repaints and resets invalidate stale partial allocations. Water uses
one surface per populated quadrant with a shared pausable city clock.

The loading, retention and safety distances stay 256px, 512px and 96px. A safety completion,
boot or explicit camera relocation drains needed work synchronously before exposure.
Unloading, the map, seeded ground variants, source cells and atlas coordinates, route tint,
water phase, collision and off-screen gameplay retain their contracts. The loading-time
shared image recipe is not the target. This keeps [M159, nearby scenery residency](2026-09-19-M159-4.md)
and [M171, the ground](2026-09-20-M171-the-ground.md).

**Choices open to overturn.** Four quadrants, a per-region frame limit, visible off-screen
pending layers and the additional water surfaces are implementation choices. The player
asked to test the global limit, not to select it. The per-region choice bounds ordinary
approach work while retaining enough throughput at slow movement-update rates; its allocation
and steady drawing overhead are measured costs. Browser or complete-game evidence can change
that assessment, and does not silently authorize a different scheduler.

**Matched before and after.** [The evidence README](../evidence/silky-rabbit-ground-frames-2026-10-02/README.md)
contains exact rerun commands, environment, source and collector identities, retained
aggregates, and limits. [Matched results](../evidence/silky-rabbit-ground-frames-2026-10-02/matched/results.json)
retain three trials each for atomic, global one-section-per-frame and per-region preparation.
One warmup per strategy precedes the nine rotated interleaved captures. Clean tracked runtime
manifests differ only in the ground and residency scripts; the collector bytes are identical.
It uses Godot 4.7.2 on Apple M2/macOS, OpenGL compatibility, VSync disabled, seed 4242,
a 1280×720 viewport and 640×360 camera view. No competing engine/test launch runs during captures.

Actual Engine frames advance identical modeled 60Hz south, 15Hz south and 15Hz diagonal
itineraries for 30 modeled seconds, 15 out and 15 back at 168px/s. These are controlled
rendered City/scenery routes, including outside-band travel, rather than playable survival
routes. Each case settles for 120 frames. A shoreline relocation then settles for 120 frames
and collects 240 steady samples. The common span starts at `SceneTree.process_frame` and ends
at `RenderingServer.frame_post_draw`, covering movement, animation callbacks, preparation,
deferred renderer work and encountered submission/waits. Atomic's deferred preparation
therefore remains in the common measurement. Queue-only timing is diagnostic, not comparable
full cost. Observation and CSV output are outside that span.

| Ordinary south 60Hz | Atomic | Global one-section cap | Per-region |
| --- | ---: | ---: | ---: |
| Median range across trials | 1.190–1.202ms | 1.088–1.091ms | 1.067–1.070ms |
| p95 range | 3.519–4.021ms | 2.859–3.041ms | 2.849–3.073ms |
| p99 range | 4.627–5.274ms | 4.310–4.532ms | 4.292–4.441ms |
| Worst retained sample | 8.710ms | 7.332ms | 7.414ms |

The ordinary-route median improves about 11%. At modeled 15Hz the tails overlap and maxima
are mixed: per-region diagonal's worst is 7.667ms versus atomic's 7.201ms. No traversal or
steady sample exceeds 16.667ms. This does not establish a universal frame-time improvement
or perceptible whole-game improvement. All 24,300 traversal frames retain complete visible
ground; all 27 settled windows have matching cells and pixels. There are no forced draws,
rejected matched trials or omitted matched outliers.

On seeing all three short-summary columns, the player assesses "okay and it didn't really
make things much faster", recorded in [freckled-beaver, the measured ground speedup is small](../playtests/2026-10-02-freckled-beaver.md).
The ordinary-route difference is about 0.13ms. This evidence verifies smaller work chunks
and a modest fixture gain, rather than establishing a noticeable stutter fix. Whether its
cost is worthwhile in real play remains open; this assessment does not select another runtime.

Asked for a verdict, the assistant recommends keeping atomic until actual gameplay stutter
profiling implicates ground. The player instead chooses to try the stepped implementation
on their phone: "I wanna see it on the phone so we will have to merge it anyway", in
[gray-stork, try ground preparation on the phone despite the small native gain](../playtests/2026-10-02-gray-stork.md).
The per-region proposal remains the implementation for that evaluation. This is a choice
to obtain phone evidence, not a claim that the native comparison proves a perceptible gain.

The global cap needs 16 southward and 31 diagonal safety completions in every 15Hz trial;
atomic and per-region need none. It has no consistent timing advantage over per-region.
The safety path prevents holes but concentrates deferred work at the last boundary, so the
stricter policy is rejected for ordinary preparation throughput, not because it draws gaps.

The settled shoreline retains identical pixels over 18 regions and 976 populated cells,
including 336 water cells. Draw calls increase from 38 to 46 and water surfaces from 6 to 24.
Clearing ground releases 482,528–482,552 tracked static bytes for atomic versus
776,624–776,720 for stepped preparation, about 61% more. This is a Godot allocation delta,
not RSS or GPU memory. Steady median spans increase from 0.792–0.814ms to 0.818–0.842ms.
The controlled City/scenery fixture excludes Main, crowds, events, physics before the process
signal, GPU duration, physical presentation, and browser/phone behavior.

**Other evidence and rejected approaches.** The isolated eight-region strategy comparison
reduces worst preparation steps from 251–279µs atomic to 103–107µs quadrants, while adding
total work and retained allocation. Rows have smaller steps but repeatedly rebuild the same
renderer quadrant and cost more total preparation and water objects; they are rejected.
Simply yielding an unchanged atomic region would leave its indivisible renderer burst intact.
Hidden pending layers discard renderer work and are rejected. Publishing partial regions
would weaken coverage semantics and is rejected.

The final rate sweep covers south/east/diagonal at modeled 15/30/60Hz with no gaps or safety
catch-ups. A separate 92px camera look-ahead reversal covers 1,800 frames and 85 regions
without either. Its 33.259ms callback outlier is retained without attributing it to ground.
The complete gameplay burst and [three-second walking/reversal clip](../evidence/silky-rabbit-ground-frames-2026-10-02/walking-reversal.mp4)
show continuous ground at a junction; capture overhead prevents using them for normal frame
timing. Earlier invalid camera fixtures and the failed optional probe launch are named and
excluded in the evidence README. The historical synchronous residency collector does not
advance Engine frames and cannot validate the current frame-gated scheduler. Its current
copy and UID are removed; the pinned historical revision retains its original runnable
copy and reproduction instructions. Current validation uses the real-process-frame probes.

**Verified.** `tools/check.sh`, `tools/lint.sh`, the ground/atlas/route-tint/residency suites,
main/finale/orientation suites, collector parse and CLI help/error checks pass. The native
probes check distinct-frame advancement, complete publication, cancellation, retention,
relocation, water/source equality and renderer spans. Local suites are partial; full-suite
CI and independent PR review are separate gates. The matched aggregates and source identities
are independently recomputed from the scratch traces. Browser/phone perception and the full
game's competing-work performance remain [a human review item](../review/2026-10-02-silky-rabbit.md).

**Cloud-review corrections.** The supplied review and the player's request to fix its
findings are recorded fully in [leafy-hare, cloud review corrections for nearby ground preparation](../playtests/2026-10-02-leafy-hare.md).
Its merge-before-phone-check question is answered by gray-stork's explicit choice to obtain
phone evidence after merging. Its required stale-probe finding is fixed by removing the
obsolete current probe, rather than retaining a file that knowingly cannot drive the new
frame fence. No live caller depends on it; archived measurements retain their pinned copy.
The stale runtime acceptance claim is removed and the architecture paragraph is rewrapped.
`worst_prepare_usec` records synchronous full-region preparation only; ordinary quadrants
use `worst_step_usec`. The metric comment and current evidence notice now distinguish them.

The two changed runtime scripts contain exactly the same executable lines as the captured
implementation. The added/removed comments mean source bytes differ; original recorded
hashes identify the captured sources, and do not claim byte equality with this correction.
Headless boot, doc lint, whitespace checks and the live-reference audit pass. The retained
timing evidence is not regenerated for a comment/probe-removal change.

The optional completed-region water consolidation and cached water-node list remain
implementation proposals open to overturn. Consolidation moves whole-region water redraw
work into completion, which is itself part of a preparation step and would need measuring;
the reviewer suggestion that step timing is unaffected is not established. A cached node
list changes lifecycle bookkeeping for pending, published, canceled and released surfaces.
This correction preserves the measured scheduler and its explicit costs for the player's
chosen phone evaluation. If phone evidence implicates those costs, the proposals return
for discussion with new measurements; this is not standing authorization to change them.
