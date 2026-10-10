# leafy-marten — The steering side is chosen on the title, for the sitting · 2026-10-10

The player, inbox #630 in [dotted-wombat](../playtests/2026-10-10-dotted-wombat.md), changing their
mind about an opposite-side tap that runs beside held steering (draft PR #631, closed unmerged):
"we don't allow switching joystick and run key. the decision is mad on the title screen. the
joystick select buttons move to where the joystick buttons will be. selecting the left one will
make the left side permanently joystick and the right side permanently run button (permanently for
the sitting). vice versa on the right side. the tap to play button goes in the center between
both." And: move the joystick's reach "closer to the run button; although I wouldn't go all the
way", a smaller dead zone, and a swipe through it that lifts outside it keeps her moving toward the
final position.

**Built in PR #637.** The title shows three buttons: a joystick button on each focal point
(`TouchControls.FOCUS_LEFT`, 240,480, and `FOCUS_RIGHT`, 1040,480) and the tap button between them
at 640,480. The left one starts the joystick scheme with the left side steering and the right side
Run, the right one the mirror; the choice travels as `ControlsMode.Side` with the scheme through
`start_requested` into `TouchControls.set_mode(mode, side)`, and across the day-14 reload into the
escape. Nothing in play swaps the sides: a press on Run's side holds Run and never steers, and Run is
drawn from the first frame. "For the sitting" is read as until the title shows again; the side is
never saved. The rig flag `--controls` (and `?controls=`) also takes `joystick-left` and
`joystick-right`.

**This replaces part of [round-gecko](2026-10-07-round-gecko.md)**, the unused joystick becomes Run,
by the player's own change of mind: its "using the joystick chooses the side" and "it's not
permanent", the both-rings start before the first press, and the swap on a press or a band crossing
are gone. Round-gecko's Run disc at the joystick's size, the 5% catch, held Run with the double-tap
latch, and per-pointer roles stay.

**Reach and dead zone, the filer's proposals as built, open to overturn.** The steering half ends
two thirds of the way to Run's focus (`STEERING_REACH`, x≈773 when the left side steers, x≈507 when
the right does); the 2026-09-07 stop band moved to that edge at its 96px width, and everything
beyond it is Run's. The dead zone is `DEAD_ZONE_RADIUS` 32px, drawn as its own faint circle inside
the unchanged 48px ring (`RING_RADIUS`). The tap scheme's stop circle on her stays half the dead
zone, as playtest 34 finding 5 asks ("exactly … the size of the joystick stop circle nothing
bigger"), so it went from 24 to 16 world px: it covers her body from 7 to 39px above her feet, and
a click on her head or her feet no longer stops her. Lifting a steering finger re-aims her at the
lift point, so a swipe through the dead zone that lifts outside it keeps her walking toward the lift
point and one that lifts inside it stops her.

**Small choices where the entry was silent, open to overturn:** the title's two teaching lines sit
in the top half and the hint under the buttons; the stop band straddles the edge, a fresh press in
its Run-side half is Run and a steering drag into any of it stops her; a steering drag carried past
the band onto Run's side steers again from the same focus; the lift re-aim is joystick-only; the
knob sits 36px out, just past the dead-zone circle, which is drawn 1.5px at 22% opacity; a press on
the edge pixel steers; GoatCounter does not record the side.

**Verified.** `./tools/check.sh` and `./tools/lint.sh` pass; the touch, orientation, pause,
encounters, held-restart, main, visible-view, HUD and finale suites pass together. Stills of the
title in landscape and rotated portrait and of both in-play layouts are in
[leafy-marten-controls-2026-10-10](../evidence/leafy-marten-controls-2026-10-10/README.md). How it
feels on a phone is the [phone review](../review/2026-10-10-leafy-marten.md)'s.
