priority: next

# golden-puffin — A builder past its context stop is told so by the harness, not only by its brief · filed 2026-11-18

**Not from the player's words.** The orchestrator files this from what it saw on 2026-11-18; the
nearest words are the player's report of an agent session using 60 GB of memory and their limit
on the cost of a builder's run.

**What happened.** Four refactor builders in a row (minty-quail's city map, building, crowd and day
reads; PRs #1526 to #1529) were briefed to stop at a clean pushed commit at 250k or 200k of context
and report, and each ran 80k to 130k past it (334k, 341k, 305k, 325k) until the orchestrator's
recurring check messaged it to stop. The last brief asked the builder to judge its context after
each class and open its pull request early; it still overran. `tools/agents-to-reassess.py`, the
orchestrator's check, notes a builder past 300k (`past-guide`) but only when the orchestrator runs
it, every 30 minutes.

**Read as:** a builder does not see its own context size, so a stop written in its brief is a
number it cannot check.

**Proposed, not asked for:** the harness tells a builder when it passes its stop, from the
builder's own transcript, in a hook that adds a line to a tool result once the transcript passes
the stop the brief names (a `context-stop:` line in the brief's opening block, beside `agent:`),
so the builder reads it in its own turn. The plainer alternative: the orchestrator's recurring
check runs every 10 minutes while a builder runs, and messages any builder past its stop. Either is
cheap to undo. Which one is the builder's design, with the reasons; the hook needs what Claude Code
gives a hook about the session's transcript, and the design says whether that is enough.
