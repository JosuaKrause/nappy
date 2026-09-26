## M100 — Small, real, and nobody's · the keyboard resets the pointer's aim, fixed 2026-09-12

*(2026-09-11, playtest 57: "arrow keys should reset any mouse click position. when pressing awsd
or arrow keys right now the last pressed mouse position is still active resulting in incorrect /
drifting movement.")* `TouchControls` locks a heading in by pressing the `move_*` actions
synthetically, and the stroller reads one input vector, so a real key added to the stale press.
One agent commit on `feature/pram-body-and-keyboard`. **What stands**: on any non-echo key press
that maps to a movement action, `TouchControls._yield_to_the_keyboard()` releases the movement
actions this node itself pressed, derived from the sign of its own locked heading, **except the
action the key just pressed**, and clears the drag, the locked heading and the drawn knob. That
exception is the ordering trap: `Input` updates an action's polled state before `_input()` sees
the event, so releasing the key's own action would cancel the key rather than the click. `run` is
released only if this node's own double press set it, so a physically held Shift is never touched.
A test reproduces the engine's ordering by hand: a click north, then a `D` press, and the input
vector is exactly right with the heading cleared.
