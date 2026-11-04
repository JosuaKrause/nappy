**Does a picked-up-but-unperformed resistance instruction expire at the end of its day, or
wait?** On main a resistance task is one day ([M181](../../decisions/2026-09-23-M181-the-resistance-has-a-reason-and-a-task-is-one-day-slice-one.md)):
`ResistanceSteps.for_day()` offers a step only on its own day, and a step left undone is not
offered on a later one, so the instruction expires at the end of its day. The question is whether
to change that, so that an instruction picked up but not performed waits for a later day.
