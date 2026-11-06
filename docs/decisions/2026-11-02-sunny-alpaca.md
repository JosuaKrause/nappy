# sunny-alpaca — The skills say how work survives an interruption · 2026-11-06


**Built.** Three skill changes, each citing inbox #986 in brisk-pelican, where the player asked that
a new session be able to reorient and continue where the previous one ended, that the board be the
player's information and answer channel, and that it be updated in batches while temporary
information stays local.

- **orchestrating**, "Recovering from an interruption": in-flight state lives in the repository,
  PRs and issues, briefs and the local restart prompt; the restart prompt is written during the
  session whenever cheap. Also the rule that an agent stopped by a session restart is resumed by
  `SendMessage` to the id on its brief (`tools/agent-status.sh` prints it per worktree) before any
  rebrief.
- **session-cleanup**, step 8: the restart prompt is kept current during the session; the handover
  rewrites it whole. The line pointing at this queue entry is replaced, and the "start fresh agents"
  line excepts agents stopped by a restart.
- **board**, "When it is read": the line that a report, merge or verdict updates the Running table in
  the same turn is replaced; the table is updated in batches.

**Observed 2026-11-06.** When the player respawned the orchestrating session, every running
sub-agent stopped; each resumed with its context intact on a `SendMessage` to its id, and its
worktree held its uncommitted work. The agents were warm, which is why the resume was cheap; the
skill gates the rule on warm, as the cold-resume rule requires. The filer's proposal, open to overturn.

**Options weighed.** Putting the restart-prompt rule only in session-cleanup (rejected: the moment
is the orchestrator's working, so orchestrating states it and session-cleanup points at it); a new
skill (rejected: the three existing ones govern these moments).

Review of the PR moved the resume rule under the cold-resume rule (warm only, newest `agent:` line,
id printed only when the transcript is found), marked both resume sentences as proposals, made
Settling's Running-table moves follow the batch rule, and added the board to the list of places
state is kept.
