# The 45-minute check is written into the orchestrating skill

**Build:** **orchestrating**'s "What the orchestrator keeps", beside the bullet that has it end its
turn to wait for the agents (gentle-owl #1196), says that while a subagent runs, the orchestrator
checks on it at least every 45 minutes, its output, its worktree and its pushes, for signs it is
stuck: no new commits, a loop that has stopped improving, a wait with no end (gentle-owl #1255).
The words and the reading are in this entry's `README.md`.

*Proposed, not asked for, and open* (the entry's `README.md`): the agent contract
(`.claude/skills/orchestrating/references/agent-contract.md`), under "A long wait gives one
notification", bounding an agent's own waits by the same 45 minutes. It is written into the
contract only once the player's words are read to reach an agent's own waits, never as the
player's rule on the strength of this entry.

**It meets the contract's one-notification rule.** That rule keeps a wait from ending a turn on
every tick, since each turn ended notifies the orchestrating session and the player. *Read as*
(the filer's, open to correction): the orchestrator's check every 45 minutes is not a tick, so the
two hold together.

*Proposed, not asked for:* how the orchestrator's check is scheduled (a recurring job about every
30 minutes, since a scheduler can fire up to half its period late, as the session that captured
the note did) is the skill's to state; the wording is the builder's.
