priority: now

# snowy-wombat — An opposite-side tap runs while steering is held · filed 2026-10-08

[jolly-egret](../../playtests/2026-10-08-jolly-egret.md) records the player asking for any tap on
the opposite side to run while the original joystick-side pointer remains down and is steering.
This refines [round-gecko](../../decisions/2026-10-07-round-gecko.md), which presently reserves
only the displayed Run disc for a Run hold and treats an opposite-side press outside that disc as
a new steering choice.

The required interaction has two distinct states. With a live steering pointer, a fresh touch in
the other side's steering area begins a Run hold and does not alter its direction, focus, drag
owner, or double-tap state; its release ends only that Run hold. Once the steering pointer lifts,
the existing retained-layout behavior stays: an opposite-side press outside the Run disc selects
that side to steer, while the Run disc itself remains a held Run control. The center stop band and
pause button retain their existing behavior.

Proposed, not asked for: “opposite side” means the half that `nearer_focus()` assigns to the focus
other than the live steering pointer's focus, excluding the existing middle stop band and pause
button. This uses the control layout’s present definition of a side and leaves a press in the
middle as Stop.

# snowy-wombat — An opposite-side tap runs while steering is held · filed 2026-10-08

