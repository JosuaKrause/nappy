priority: next

# tawny-quail — Follow-ups from the review of the PRs merged without an orchestrator · filed 2026-10-03

> "double check all PRs since then and record each defect or comment in a new single review PR (if
> anything needs to be done)."

[busy-ibis](../../playtests/2026-10-03-busy-ibis.md), statement 1. Every PR merged between v0.21.0
and #456 got an after-the-fact review posted on the PR itself, as `claude-reviewer`, naming the
verdict it would have had. This entry holds what those reviews found that is still wrong on
`main`, one item per area, each naming the PR and the review it comes from; the write guard's
findings are their own entry, [dappled-owl](../2026-10-03-dappled-owl/README.md). A PR not named here
has nothing left on this entry: #421, #430, #438, #443 and #444 had no open finding; #422's is built
by open PR #429 (the inbox's `show` prints the agent's question beside the player's answer); #425's
were fixed by #462; #461's were fixed on its branch, and the nit left at its merge by this PR's
**session-captures** edit. #456's findings are about the calm-stork, round-ferret and velvet-hare
entries, which open PR #457 builds and deletes, so they were raised on #457, where they belong.

**Proposed, not asked for:** the band `next`. None of these breaks the game: they are tests that
cannot fail, docs and comments that say something false, one unmet measurement and one wasted
preparation.
