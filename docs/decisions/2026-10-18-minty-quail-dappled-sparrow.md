# minty-quail — The touch controls', park cordon's and frame recorder's members only their own class used become internal · 2026-11-06


minty-quail's `tests-own-class-members.md`, the underscore pass, for its first three owners: a
public member that only its own class and the tests use gets a leading underscore and its tests
move to what the class does outward (curly-rabbit #1098), and one that turns out to have no reader
once its test moves is deleted (curly-rabbit #1095).

**Built.** The touch controls' geometry is internal: the heading toward a press, the dead zone,
the stop band, the steering half's edge, which half is Run's, Run's focus, the covered screen and
the direct heading setter. The touch suite presses real touches and clicks and reads the actions
the stroller steers by; the suites that fed the world a covered screen take it from
`TouchControls.covering` through `tests/touch_cover.gd`, and the finale rig and the pause suite
click instead of calling the setter. The park cordon's officers, stretches, closing time, trapped
state and deadline are internal, and `first_in_view`, `relaid`, `walked_straight`,
`gap_reaches_home`, `gap_clear` and `other_calm_reached` went or became locals; the cordon suites
read the officer figures, the tape's bodies, the obstructed edge tiles
(`tests/cordon_in_the_world.gd`), the hard-fail signal and the cordon's `elapsed`. The frame
recorder's and ledger's probes are internal and `save_on_exit` is deleted; their suites read the
record saved to a scratch path, the ledger's `report()`, the readout line and the draw counters.

**Kept public**, each with its reason beside its line in the list's `[kept]` group:
`TouchControls.current_heading`, which only the knob draws; `TouchControls.run_button_center`,
which the booted-main suites ask while a title or brief pauses the tree and a press reaches
nothing; `ParkCordon.last_gap`, since a test stands her at the gap before any tape shows it.

**Open to overturn.** Four cordon checks went rather than converting: "closes when the cordon said
it would" and "first officer in view when it said", which compared the cordon with its own
promise; the stalled-officer count with `relaid == 0`; and the escort-alone test's "gap held for
him" half, which needed a speed only a test can write, so that test is now "let out before the gap
shuts" and the slow-walker test covers a held gap.
