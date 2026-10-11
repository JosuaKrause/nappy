Reproduce the complete day-12 sequence: take the park through its task, walk back with the baby
asleep, and reach the reported softlock. Establish whether movement stops, home never accepts the
return, the day fails to advance, or the engine freezes; the note does not say which. Retain the
failing seed and sequence so the fix tests this combination rather than an unrelated sleeping-home
return.

The park is now taken by [plush-marten](../../decisions/2026-10-10-plush-marten.md)'s police cordon
rather than mud rings, so no ground is repainted during day 12. With it, the route rig
(`tools/run.sh --seed <s> --day 12 --route mark,task,calm,home --invincible --no-focus-pause
--no-title`) on seeds 4242, 11 and 13 touches the swing, settles the baby elsewhere while the park is
taped with her outside, walks home with the baby asleep and wins the day with no error; the rig stops
at the win, so the summary screen and the next morning are not exercised. What is left: run past the
win into the day summary and day 13, and play the case the rig does not, being taped in or leaving
through the last gap with the baby asleep. If nothing reproduces, close this item and say so in its
record.

Inspect `ParkCordon` (`src/resistance/park_cordon.gd`) and `Happenings.take_the_park()`, and the
return/day-summary transition in `DayController`. Read the current park/routing rules alongside
[M181, the park task](../../decisions/2026-09-24-M181-the-resistance-has-a-reason-and-a-task-is-one-day-slice-two.md);
being shut in by the cordon now ends the day, as the player chose in
[azure-puffin](../../playtests/2026-10-10-azure-puffin.md). Add a focused regression through the real
failing transition, preserving the sleeping-baby condition. Open for pickup: seed and the exact form
of the softlock.
