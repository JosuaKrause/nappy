priority: now

# gray-trout — No wait runs longer than 45 minutes without a check-in · filed 2026-11-09

**The ask.** Said right after the orchestrator found a builder (placement by construction's step of
the per-view bags, #1254) running a fit loop for over an hour, with `until grep ...; do sleep 30;
done` waits of up to 10 minutes each and nothing pushed in three hours, while the orchestrator
itself waited only for that agent's completion notice: "also never sleep longer than 45min", and
then "when waiting for subagents to complete check every 45min to see if they got stuck"
(gentle-owl #1255). The note carries the band `now`.

**Read as:** the player's words govern the orchestrator's waits. While a subagent runs, the
orchestrator checks its output, its worktree and its pushes at least every 45 minutes for signs it
is stuck (no new commits, a loop that has stopped improving, a wait with no end), rather than
relying only on the completion notice; no wait of its own runs past 45 minutes without such a
check. The second quote says so of the orchestrator alone, and the wait the context shows running past 45
minutes is the orchestrator's own, on one completion notice while nothing was pushed in three
hours; the builder's sleeps were up to 10 minutes each.

*Proposed, not asked for* (the filer's; the reading captured with the note included it): an agent's own waits (a background run, a fit loop, a CI wait) are bounded by the same 45
minutes, the agent pushing what it has or reporting rather than waiting on. **Open,** for whoever
picks this up: whether "never sleep longer than 45min" reaches an agent's own waits at all; a bound
written into the agent contract would cut runs that are legitimately long.

**Item:** `forty-five-minute-check.md`.

*Proposed, not asked for:* this entry is not held behind minty-quail, although that entry fences
other work (gentle-owl #1210): the fence's reason is work done twice on code the refactor changes,
and a skill's text is not such code.
