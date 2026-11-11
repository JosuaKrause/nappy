# amber-swan — Agents read CI through the GraphQL status call · 2026-11-11 · not from an entry

**What happened.** On 2026-11-11 at about 02:05Z the account's GitHub REST quota read 0 of 5000 for
the hour, while GraphQL still answered. The most likely cause was one builder's `gh run watch`,
which polls the REST API every few seconds, beside several background watchers. The cause was read
from what was running, and not measured. The builder was told to stop, the watchers moved to GraphQL,
and the night's briefs carried the rule by hand.

**What the agent contract now says.** CI's state is read with `gh pr view <n> --json
statusCheckRollup`, at most every ten minutes, in the one background wait the contract already
allows. `gh run watch` is never used, and a REST call is only for reading a failed job's log once,
which the contract's sentence on a red pull request needs.

**Proposed, not asked for.** The rule and the ten minutes are the orchestrator's, not the player's
words. A wait by `tools/await-merge.sh` is not changed by this.
