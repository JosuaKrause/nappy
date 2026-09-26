## M142 — A layer turned off is drawn off · built 2026-09-14

*(2026-09-14, [PLAYTEST-75](../playtests/PLAYTEST-75.md): "pressing number keys to turn off a
layer doesn't remove the layer anymore. for example if I press 2 twice I have ghost circles
all over".)* One agent commit on `feature/m142-debug-layer-ghost`, reviewed on the PR.

**What it was.** `DebugLayers` draws the three overlays from one retained `_draw()`, and the
M124 gate (below, "DebugLayers stops walking the city tree when every layer is off") made its
`_process` queue a redraw only while a layer is on. A retained `_draw()` keeps its last picture
until the next `queue_redraw()`, so the key that turned the last layer off changed the boolean
and nothing asked for the frame that would draw nothing: the shadow outlines stayed on screen
until something else redrew the node, which nothing did.

**What it is.** `set_layer()` and `apply_initial_state()` set a private `_redraw_owed` flag;
`_wants_a_redraw()` answers true while any layer is on or the flag is set; `_process` clears
the flag when it queues. So the switch-off queues exactly one empty `_draw()` and a view with
everything off goes back to costing nothing a frame after it. The gate and its reason stand.
The test beside the gate's own turns a layer on and off through `set_layer` and asserts a
redraw is wanted once and not after `_process` has run; `queue_redraw()` on a node outside
the tree was checked to be harmless rather than assumed.

**One choice made where the design was silent, open to overturn.** The flag is set on every
`set_layer` call, including one that sets a layer to the value it already had, rather than only
on a change: an extra empty redraw on a no-op toggle costs nothing the gate was built to avoid,
which was the continuous per-frame call.
