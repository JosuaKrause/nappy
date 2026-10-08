Reproduce the complete day-12 sequence: close the park through its task, walk back with the
baby asleep, and reach the reported softlock. Establish whether movement stops, home never
accepts the return, the day fails to advance, or the engine freezes; the note does not say which.
Retain the failing seed and sequence so the fix tests this combination rather than an unrelated
sleeping-home return.

Inspect `Happenings.take_the_park()` and its closure progress, `City.close_ground()`, and the
return/day-summary transition in `DayController`. Read the current park/routing rules alongside
[M181, the park task](../../decisions/2026-09-24-M181-the-resistance-has-a-reason-and-a-task-is-one-day-slice-two.md),
whose original closure guarantee is "she is never shut in". Do not change what closing the park
means to avoid reproducing the fault. Add a focused regression through the real failing
transition, preserving the sleeping-baby condition. Open for pickup: seed and the exact form
of the softlock.
