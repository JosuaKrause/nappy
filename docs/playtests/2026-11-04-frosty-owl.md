# Playtest frosty-owl — Inbox filing: run-state leftovers, CI timings cache, restart prompt first

2026-11-04.

## #1060

1. **Context** (the assistant's):

   Asked in the session (2026-11-04): minty-quail's run-state step ("the run's state is made fresh and handed in, not a global", run-state-handed-in.md) has its last wave in PR #1058, which removes the GameState stand-in. Three changes are left on the item as the orchestrator's proposal under the entry's "no legacy shape is kept" rule (minty-dolphin #852), not in the player's words: RunState as a RefCounted instead of a Node the Sitting holds as a child; a held restart handing the sitting a new run object instead of start_run() in the same one; and src/autoload/game_state.gd renamed for what it holds and moved out of src/autoload/. The orchestrator said it had kept them queued and marked them proposed, and asked the player to say if any should be dropped.

2. **The note.**

   > that sounds good

3. **Read as:** (the assistant's interpretation, not the player's words)

   The player agrees to keep all three leftovers queued on the run-state item.

## #1061

1. **Context** (the assistant's):

   Said in the session (2026-11-04) after the orchestrator refreshed tests/suite_costs.txt twice by hand-run PRs (#1041, #1049: tools/ci-costs.sh averages the last green CI runs' per-suite timing lines and rewrites the checked-in table that tools/test.sh bin-packs CI's eight shards from).

2. **The note.**

   > is there a way we can cache the CI timings? that way the next CI can read the previous version and balance using that info on the fly

3. **Context** (the assistant's):

   Said in the session (2026-11-04), in this order, as the design of this note was discussed. The orchestrator answered that the two-key cache scheme works (a prefix restore of suite-costs-v1- cannot match suite-prev-costs-v1-, every shard and a re-run of one shard read the same frozen table, a pull request run falls back to main's newest); that an artifact from the plan job would do the same (overwrite: true and a short retention); and that a job output (the plan job writes the table to $GITHUB_OUTPUT, the shards read needs.plan.outputs.costs, about 6 KB against a 1 MB limit) needs neither, and recommended it. The last words agree to the job output, for the plan's table and for the per-shard timings handed back to the end job, with retention set on any artifact used.

4. **The player's words.**

   > my idea would be to have suite-costs-v1-${{ github.sha }} that is written at the end with the current sha's timings and one suite-prev-costs-v1-${{ github.sha }} that is written at the first step with the value of suite-costs-v1- and the shards read suite-prev-costs-v1-${{ github.sha }} exactly (including the sha so no latest but exactly the sha). could that work?
   >
   > can the plan job upload an artifact for the shards to read?
   >
   > what's a job output? if that works also good
   >
   > yes, let's do that also for the individual timings don't forget to set the retention either

## #1062

1. **Context** (the assistant's):

   Said in the session (2026-11-04) right after the orchestrator, starting a fresh session, read only the top of .claude/restart-prompt.md (a 310-line log whose newest state is at its end, while its top still described 2026-11-02's work as in flight) and answered "what comes next" from the minty-quail queue item instead; the player asked "hmm you're reading from minty-quail instead of the handoff?". CLAUDE.md's "where to pick up" paragraph names the restart prompt last, after the live-state commands.

2. **The note.**

   > maybe put a note in claude md to always look for restart prompt first when you're the orchestrator

## #1065

1. **Context** (the assistant's):

   Said in the session (2026-11-04) right after the orchestrator put a "NOW" section at the top of .claude/restart-prompt.md, above a log of about 300 lines kept since 2026-11-02 (inbox #1062: a fresh session had read only the stale top of that log).

2. **The note.**

   > maybe improve the layout of the restart prompt and routinely remove old entries

3. **The player's words.**

   > or have a systematic way of reading it
