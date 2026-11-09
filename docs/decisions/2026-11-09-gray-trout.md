# gray-trout — The orchestrator checks a running agent at least every 45 minutes · 2026-11-09

**The ask.** The orchestrating session had found a builder running a fit loop for over an hour,
with waits of up to 10 minutes each and nothing pushed in three hours, while it waited itself only
for that agent's completion notice. The player: "also never sleep longer than 45min", then "when
waiting for subagents to complete check every 45min to see if they got stuck" (gentle-owl #1255).

## What was built

**orchestrating**'s "What the orchestrator keeps" carries the rule beside the bullet that has the
orchestrator end its turn to wait for its agents (gentle-owl #1196): while a sub-agent runs, the
orchestrator looks at it at least every 45 minutes (its output, its worktree and its pushes) for
signs it is stuck (no new commits, a loop that has stopped improving, a wait with no end), and no
wait of its own runs past 45 minutes without such a check. The completion notice alone is not
enough, since a stuck agent never sends it.

Two parts of the text are marked as not the player's:

- *Proposed, not asked for:* the check is a recurring job about every 30 minutes, since a scheduler
  can fire up to half its period late, deleted when no agent is left running. The session that
  captured the note ran it that way.
- *Read as, open to correction:* the check is not a tick in the sense of the agent contract's
  one-notification rule ("A long wait gives one notification"), which keeps a wait from ending a
  turn on every poll. The two hold together: the contract bounds how often an agent's wait
  notifies, and this rule bounds how long the orchestrator goes without looking.

## What was not built, and why

**No bound on an agent's own waits is written into the agent contract.** The filing proposed one
(an agent's background run, fit loop or CI wait bounded by the same 45 minutes, the agent pushing
what it has or reporting instead of waiting on) and left open whether the player's words reach an
agent's own waits. *Read as, the orchestrating session's, open to the player's correction:* they do
not. Both sentences were said to the orchestrator about its own waiting; the second names the wait
("when waiting for subagents to complete"); and in the case the player was answering, the wait that
ran past 45 minutes was the orchestrator's, while the builder's own sleeps were 10 minutes at most.
A bound in the contract would also cut runs that are legitimately long (a whole-suite run, a
many-seed probe), which the orchestrator's check already covers from outside: a long run that is
still producing output is not stuck, and one that has stopped is found within 45 minutes. If the
player wants agents bounded too, it is a line under the contract's "A long wait gives one
notification" and a new entry.
