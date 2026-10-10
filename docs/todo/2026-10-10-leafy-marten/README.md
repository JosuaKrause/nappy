priority: now

# leafy-marten — The steering side is chosen on the title, for the sitting · filed 2026-10-10

[dotted-wombat](../../playtests/2026-10-10-dotted-wombat.md), inbox #630, in the player's `now`
band. The player's words appended to the note replace its first request (an opposite-side tap
runs while steering is held), which draft PR #631 was building; #631 is closed unmerged:

> we don't allow switching joystick and run key. the decision is mad on the title screen.
> the joystick select buttons move to where the joystick buttons will be. selecting the left one
> will make the left side permanently joystick and the right side permanently run button
> (permanently for the sitting). vice versa on the right side. the tap to play button goes in the
> center between both.

> we can even increase the influence zone of the joystick (instead of splitting the in middle we
> can move it closer to the run button; although I wouldn't go all the way). also decrease the
> deadzone of the joystick (which makes the player stop) smaller/tighter and make sure swiping
> over it but landing outside of it correctly keeps the player moving in the direction of the
> final position.

**It replaces part of [round-gecko](../../decisions/2026-10-07-round-gecko.md), the unused
joystick becomes Run**, by the player's own change of mind: round-gecko let steering on either
half choose the side and let a later steering press on the other half swap the roles ("it's not
permanent"). From this entry on the side is chosen once, on the title, and never swaps during
play. Round-gecko's Run disc at the joystick's size, its 5% catch beyond each button's painted
radius (`ButtonGeometry.CATCH_SCALE`, 1.05), its held-Run and double-tap run latch, and its
per-pointer role ownership stay. Its phone review,
[round-gecko](../../review/2026-10-07-round-gecko.md), asks the player to try swapping sides, so
the PR that builds this rewrites or replaces it.

The items: [title-chooses-the-side.md](title-chooses-the-side.md),
[joystick-zone-and-dead-zone.md](joystick-zone-and-dead-zone.md),
[the-re-review-findings-in-these-files.md](the-re-review-findings-in-these-files.md).
