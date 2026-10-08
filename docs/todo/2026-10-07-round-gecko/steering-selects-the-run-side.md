# Steering selects the run side, and button catches follow their visible radius

In joystick mode, steering with either a tap or a drag selects that focal point for steering.
The other focal point displays a Run button in place of its joystick, using the same visible
radius as the joystick ring. Remove the separate inward run buttons. Releasing the steering
pointer preserves the selected side and the existing locked heading. A later steering action
from the other side swaps the roles; there is no saved handedness setting or separate selector.
Dragging across the middle retains the current stop-band behavior and selects the new focus
when steering resumes on the other side.

Only a press beginning on the currently displayed Run button starts a run hold. A steering
pointer sliding across it keeps steering. A run pointer remains a run pointer until it releases,
even if another steering action swaps the displayed sides. Holding Run must coexist with tapping
or dragging to steer, and releasing it must preserve a double-tap run latch. Pausing, hiding the
controls, ending the day, and changing modes must not leave a held input stuck.

**Proposed, not asked for:** before any pointer chooses a side, show both joysticks; tapping or
dragging on the other side outside its Run button chooses that side for steering. The Run disc
itself remains reserved for running. This follows the existing whole-half steering surface
without adding a gesture. Preserve the chosen side across pause/resume, and clear it when the
control scheme changes or the controls are reconstructed for a new day. Keyboard input does not
pick an arbitrary side.

Apply a shared 1.05 multiplier to the visible radius for button hit testing, including Run,
pause, and the round title/pause/summary buttons. Their radial hit testing and hover behavior
must agree in ordinary and rotated presentation. The joystick dead-zone radius and the middle
stop band stay unchanged. Preserve existing background continue actions and restart hold
semantics; these are separate from button geometry.

Update the mechanics, architecture, affected comments, and focused input tests together. Verify
real pointer ownership, tap retention, bidirectional side changes, drag crossings, independent
run holds/latches, pause and mode changes, rotated input, and button hits just inside and outside
the 5% margin. Inspect rendered left-steering and right-steering layouts. Phone feel belongs in
a human review item, replacing the superseded polite-swan run-button review.
