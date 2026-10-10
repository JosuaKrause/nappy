# The joystick's reach grows toward Run, and its dead zone shrinks

Three changes, all in joystick mode, built with the title item since they depend on fixed sides.

**The steering side reaches past the middle.** Today the screen splits at its middle, x=640, with
the stop band of the player's 2026-09-07 ask ("a narrow band in the middle of the screen (size of
the stop circle) that stops the player", `TouchControls.is_in_stop_band()`) down that line. The
player: "instead of splitting the in middle we can move it closer to the run button; although I
wouldn't go all the way". **Proposed, not asked for:** the boundary sits two thirds of the way
from the steering focus to Run's focus, x≈773 when the left side steers and x≈507 when the right
does, which leaves about 216px between it and Run's catch rim; the stop band moves with it, at
the same width. Everything on Run's side of the boundary belongs to Run, so a press there holds
Run (read as: "the right side permanently run button" makes that half one button). The plainer
alternative is to keep Run's catch at its disc and leave the rest of that side inert.

**The dead zone is tighter.** `TouchControls.STOP_RADIUS` (48 design px) is both the joystick's
drawn ring and the press radius that reads as stop, and `RUN_RADIUS` is derived from it, so Run
matches the joystick's size as round-gecko asked. The player asked for the dead zone "smaller/
tighter" and named no number. **Proposed, not asked for:** a dead zone of 32 design px, drawn as
its own inner circle inside the 48px ring, which keeps the ring and Run at their current size.
`TAP_STOP_RADIUS` (the tap scheme's stop circle on her, half of `STOP_RADIUS` in world px)
stays equal to the joystick's stop circle on screen, as playtest 34 finding 5 asked ("the stop
circle on the player should exactly be the size of the joystick stop circle nothing bigger"), so
it shrinks with it; the PR description says so, since the tap scheme changes too.

**A swipe through the dead zone keeps her moving.** A drag that passes over the dead zone and is
released outside it walks her in the direction of the final position from the focus, never
stops her. **Proposed, not asked for:** a press, or a drag released, inside the dead zone stops
her, as a press there does today. Test both: a drag that crosses
the dead zone and ends outside it, and one that ends inside it.

Verify with `./tools/test.sh touch orientation pause encounters held_restart` and gameplay stills
of both layouts embedded in the PR description. Not one of verify's local-full-run cases.
