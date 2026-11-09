priority: now

# gray-trout — No wait runs longer than 45 minutes without a check-in · filed 2026-11-09

**The ask.** Said right after the orchestrator found a builder (placement by construction's step of
the per-view bags, #1254) running a fit loop for over an hour, with `until grep ...; do sleep 30;
done` waits of up to 10 minutes each and nothing pushed in three hours, while the orchestrator
itself waited only for that agent's completion notice: "also never sleep longer than 45min", and
then "when waiting for subagents to complete check every 45min to see if they got stuck"
(gentle-owl #1255). The note carries the band `now`.

**Read as:** no wait, by the orchestrating session or by an agent it runs, goes longer than 45
minutes without a check-in. While a subagent runs, the orchestrator checks its output, its worktree
and its pushes at least every 45 minutes for signs it is stuck (no new commits, a loop that has
stopped improving, a wait with no end) rather than relying only on the completion notice. An agent's
own waits (a background run, a fit loop, CI) are bounded the same way: within 45 minutes it pushes
what it has or reports, rather than waiting on. The second sentence of the player's confirms the
orchestrator's side; the agent's side rests on the first, "never sleep longer than 45min", said of
the builder's waits.

**Item:** `forty-five-minute-check.md`.

*Proposed, not asked for:* this entry is not held behind minty-quail, although that entry fences
other work (gentle-owl #1210): the fence's reason is work done twice on code the refactor changes,
and a skill's text is not such code.
