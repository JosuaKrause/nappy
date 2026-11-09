# The 45-minute check is written into the orchestrating skill and the agent contract

**Build:** **orchestrating**'s "What the orchestrator keeps", beside the bullet that has it end its
turn to wait for the agents (gentle-owl #1196), says that while a subagent runs, the orchestrator
checks on it at least every 45 minutes, its output, its worktree and its pushes, for signs it is
stuck: no new commits, a loop that has stopped improving, a wait with no end (gentle-owl #1255).
The agent contract (`.claude/skills/orchestrating/references/agent-contract.md`), under "A long
wait gives one notification", bounds an agent's own waits by the same 45 minutes: a background
run, a fit loop or a CI wait that would outlast it is cut, and the agent pushes what it has or
reports. The words and the reading are in this entry's `README.md`.

**It meets the contract's one-notification rule.** That rule keeps a wait from ending a turn on
every tick, since each turn ended notifies the orchestrating session and the player. *Read as*
(the filer's, open to correction): the two hold together, since one check-in every 45 minutes is
not a tick, and the contract's bound is on how long one wait runs, not on how often it wakes.

*Proposed, not asked for:* how the orchestrator's check is scheduled (a recurring job about every
30 minutes, since a scheduler can fire up to half its period late, as the session that captured
the note did) is the skill's to state; the wording is the builder's.
