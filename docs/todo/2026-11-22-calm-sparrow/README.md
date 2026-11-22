priority: later

# calm-sparrow — An event's caret strength may depend on whether its look asked earlier in the same tick · filed 2026-11-22

No player's words name this; it is a finding of the Opus review of [#1638](https://github.com/JosuaKrause/nappy/pull/1638#pullrequestreview-6014446627) (minty-newt, the events' looks are handed the drawn view; `git show 58ca0869d --stat`).

**Found.** The excitement fingerprint probe (`tests/probes/excitement_fingerprint.gd`) was run with its events always drawn (no drawn view handed) and again gated by the screen. Two caret values for one event flipped: `car_accident`, seed 4242, day 1, ticks 223 and 225 (caret 1 on one side, caret 0 on the other, as main has it).

**What holds today.** The caret is a drawing cue, not a charge: only `EventLook` and `CrowdAgent` read `caret_strength()`, and what an event charges her (`contribution_at`, `expected_gross_at`, `expected_impact_at`) did not flip. Whether the look's gate asking `caret_strength()` changes what a later ask in the same tick answers is unverified. The review names a likelier cause: the probe itself, which matches base and branch once its rigs hand `DrawnView.on(t)`.

**First step: verify.** Run the probe on main with and without `DrawnView.on(t)` handed to its builder, as #1638 built it, and diff the `XF` lines; then hand `DrawnView.on(t)` in both rigs and see whether the flip stays. If it goes, the probe is the fix and the entry closes.

**What the fix must hold, if the flip stays.** The caret an event shows is the same whether or not its look was asked earlier in the tick: asking `caret_strength()` is side-effect free, or the value is derived once per tick and read by every asker.

*Proposed, not asked for:* the band `later`, since no decision or doc names what a difference would break and the finding is unverified. It moves to `bug` only if a player would see the difference.
