# silver-ibis — Relevant evidence instead of whole-run archives · 2026-10-03

[busy-wombat](../playtests/2026-10-03-busy-wombat.md) asks to omit logs and unrelated
screenshots that do not serve a run's purpose, and to reduce the existing archive too.
The prior playtest-feedback and session-captures instructions required copying complete
run folders. That requirement accumulated incidental screenshots and generic logs,
and multiplied them across full worktree checkouts.

The rule retains only artifacts supporting the intended claim or its limits, including
relevant failures and contradictory trials. A README or manifest identifies source,
command/settings, relevant seed/timing, claim and selection rationale. Logs remain when
they prove ordered behavior, non-replayable input, necessary diagnostics or provenance
not otherwise retained. Generic startup output and redundant copies are omitted.
Selected telemetry evidence keeps its original run-directory identity; copying every
other file from that directory is unnecessary. The texture-integration recipe follows
the same rule. Historical sources remain intact.

Verification: doc lint and whitespace passed. A targeted live-guidance search found no
remaining whole-run-copy mandate. The rule change requires no game tests or captures.
The requested reduction is applied through ordinary tracked deletions. The player
explicitly defers Git filtering; no history rewrite or garbage collection is performed.

The archive audit measures 7,138 files / 1,084,895,544 bytes before selection and
6,942 files / 1,046,069,781 bytes afterward: 38,825,763 bytes (37.03 MiB) removed
across eight groups. This is a working-tree reduction, not reclaimed Git history.

| Group | Retained proof | Removed material |
|---|---|---|
| M130, halo/body registration | Six original frames (12 and 20 for each mode), cited crops, logs and timestamp/source metadata. The failed turning capture remains explicit; stills do not prove turns. | Other frames and three plan maps; burst sidecars replaced with accurately named still selections. |
| M108, car wheels/body | Original contiguous frames 13–28, exact timestamps/end boundary, cited source sheet and differences. These show moving-to-stopped behavior, with steering caveat retained. | Approach/extended stationary frames, redundant full MP4, plan map and routine log. |
| M159, scenery animation | Accepted animation/performance comparisons, failed fixture frame000 and original error log. | 35 byte-identical failed-fixture frames and irrelevant shoreline map/log. |
| M124, rendering-cost measurement | All original measurements, including invalid instrumented timing. | Eleven plan maps that do not measure cost. |
| M124, rendering-cost fixes | Logs, pixel comparisons and full relevant cafe/dog/walker sequences. | Fourteen plan maps. |
| M159, nearby scenery implementation | Reversal bursts, timing clips, ordered logs and obstacle-limited travel caveat. | Two plan maps. |
| M108, walker stride | Full relevant stride sequence/timing and slow-walker/delayed-loss limitations. | Two plan maps and a post-burst loss screen unrelated to stride. |
| M100, water/smoke/steam | Complete effect phases and intervals, logs, crops and sheets. | Two unrelated city-plan maps. |

All 6,930 retained artifacts outside the edited metadata/READMEs are byte-identical.
Selected timestamps match original manifests; car frames are exactly the original
13–28 span. A scan of 73 remaining burst manifests found no newly missing references.
The M118 crash-body gap-walk sidecar already names 31 absent frames, unchanged by this
selection; this is not a claim that the whole archive is valid or globally minimal.
Profiling streams, frozen art inputs, meaningful rejected work and non-replayable player
runs retain their purposes. Size alone is not a deletion criterion. Lint and whitespace pass.
