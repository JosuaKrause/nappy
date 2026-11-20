# sandy-trout — The rules hook passes a retried edit only once the transcript shows each named skill read · 2026-11-19 · not from an entry

**Why.** The rules hook (`.claude/hooks/project-rules.sh`) refuses the first edit of an area until the skills
that govern it are read whole (inbox #1267 in olive-ferret), and until this change the same edit made again
passed with nothing checking the reading: its header held that a hook judging the reads "could refuse an edit
for good on a skill that reached the session another way". The agent contract was then changed to say a
refusal is answered by reading, never by a retry (#1511), and two builders still retried a refused edit
without reading the skills it named (the orchestrating session's observation on 2026-11-17 and 2026-11-18,
the first builder of polite-tapir step 4's 3b part and the finisher of a run's parts). The written rule
alone did not hold.

**What was built.** On a retry, the hook reads the transcript of the session or the sub-agent making the call
(a sub-agent's is `<session transcript without .jsonl>/subagents/agent-<agent_id>.jsonl`, derived from the
payload's `transcript_path` as the agent-stats hook and the resume guard derive it) and looks, for each skill
the refusal named, for a tool call that reads it: a `Read` of its `SKILL.md`, a `Skill` call naming it, or
any tool call whose input contains `.claude/skills/<name>/SKILL.md`. A read before the refusal counts; the
refusal's own index, a tool result, does not. Every skill read: the edit passes. One not: refused again, naming
only the unread skills. The third attempt at an area passes whatever the transcript shows, with a context line
saying no read was seen, so a skill that reached the session another way costs at most two refusals. A missing
or unreadable transcript lets the edit pass with a context line. The check is a `grep` and a `jq` over the
matching lines (about a tenth of a second on an 87 MB transcript).

**Rejected.** Leaving the plain retry and relying on the contract's sentence (it did not hold); a check with no
cap (it could refuse for good, the header's old concern); a Python reader (slower to start on every edit).

**Open to the player's correction.** The whole mechanism is the orchestrator's proposal, put to the player on
the board (question `rules-hook-read-check`, built on its pick): the check itself, what counts as a read, and
the cap of three attempts. That a sub-agent's PreToolUse payload carries the parent's `transcript_path` is
inferred from the other hooks, not captured; the refusal names the transcript it looked in, so the first
sub-agent retry after the merge shows it.
