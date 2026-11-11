# amber-swan — Agents read CI through the GraphQL status call · 2026-11-11 · not from an entry

**What happened.** On 2026-11-11 at about 02:05Z the account's GitHub REST quota read 0 of 5000 for
the hour, while GraphQL still answered. The most likely cause was one builder's `gh run watch`,
which polls the REST API every few seconds, beside several background watchers. The cause was read
from what was running, and not measured. The builder was told to stop, the watchers moved to GraphQL,
and the night's briefs carried the rule by hand.

**What the skills now say.** **committing** holds the rule for every session: CI's state is read
through GraphQL, a pull request's with `gh pr view <n> --json statusCheckRollup` and `main`'s
through `gh api graphql`; `gh run watch` is never used; and REST is for what GraphQL does not hold,
read once and never in a wait (a job's log, a test's time in a shard's log, whether a workflow run
started at all). The agent contract and **pr-review** point there. The contract adds that a wait
reads at most every ten minutes and ends when the `test` row has a conclusion and no row is
unfinished, since the list is empty or short right after a push.

**Proposed, not asked for.** The rule and the ten minutes are the orchestrator's, not the player's
words. A wait by `tools/await-merge.sh` is not changed by this.
