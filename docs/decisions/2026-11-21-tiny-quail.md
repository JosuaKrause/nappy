# tiny-quail — A screen-edge danger badge is a typed value · 2026-11-22

**What was asked.** Fable's design `badge-value.md`, from its review of #1567 (the run log is handed the edge's badges),
a pull request of polite-tapir whose design Opus wrote in Fable's place; the player, shown Fable's six verdicts, asked for
each change to be built and Fable to review it again (the record calm-lemur). Built as #1632 by a Sonnet agent, reviewed
adversarially, then by Fable against its design.

**What was built.** A screen-edge badge the run log reads is `EdgeBadges.Badge`, a value built with its three values and
asked for the name the log calls the thing by, its distance from her and how fast it closes; `announcing()` answers those.
The badge model keeps one typed list of `BadgeModel.Drawn` badges, built once a step and sorted by when each arrives,
each also asked when it arrives, its row and where it points; the public untyped list of positional rows is gone. The run
log's observer and the edge's drawing ask the methods; the suites, the masked-man rig and the corner probe (a caller the
design did not list) do too.

**Differences from the design:** `announcing()` hands out a fresh array of the same objects, which GDScript requires (a
function declared to answer the base's badges cannot answer the model's list of drawn ones).

**Measured.** On main and the branch, on a headless day that raises badges (seed 4242, day 6, routed to her mark, a
charging dog forced, and separately a cyclist), every run-log line the branch printed main printed too, over eight runs a
side for the dog and two for the cyclist: two edge-badge lines each, whose distances (where the badge goes up and where
it goes) vary from run to run with frame timing on both sides. The day the design named raised no badge, since its walk
left her on the doorstep.
