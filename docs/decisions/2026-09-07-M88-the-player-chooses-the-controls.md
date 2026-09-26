## M88 — The player chooses the controls · built 2026-09-07

*Asked for one scheme chosen nowhere on 2026-09-06 ("get rid of all other modes") · overturned to
two schemes the player picks between on 2026-09-07: "let's make the controls a player choice and
bring back the two buttons (joystick vs tap) to choose the input mode everywhere (independent of
whether tap is available) ... both modes for in both settings so let's let the player choose instead
of forcing one."* M82's central decision, taken back by the person who took it.

**What the two words mean is not what they meant under M82, and that is the whole of getting this
right.** Then, "stick" was a dragged analog stick and "tap" walked her to a *destination*. **Neither
mechanism came back and neither is going to** — the destination least of all, since *a tap that
pathfinds hands the route decision to the game* and the route decision is the design. The two modes
are the **two aiming origins the one scheme already had**, split apart and offered:
`Mode.JOYSTICK` aims from whichever of `TouchControls.FOCUS_LEFT` (240, 480) or `FOCUS_RIGHT`
(1040, 480) is nearer, draws both circles and stops her on a focus or in the middle band;
`Mode.TAP` aims from her own world position, draws nothing and stops her on a press near her.
Everything else — one press sets a heading, a double press runs, a held pointer re-aims, every
heading normalised to one speed — is shared and untouched.

**`TouchInput.available()` was doing two jobs and now does one.** It answered *"is this a touch
device"* and was used to mean *"which aiming origin"*, which is why the modes could not be offered
independently of the hardware. It now gates only the event routing in `TouchControls._input()` — a
raw `InputEventScreenTouch` versus an `InputEventMouseButton`, plus the emulated-click guard — and a
separate `_mode` carries the choice. **So a mouse drives joystick mode and a thumb drives tap mode**,
which is exactly *"independent of whether tap is available"*.

**The mode is a setter, not a value read once at `_ready()`.** `TouchControls.set_mode()` is called
from `main` — once with `ControlsMode.resolve()` as the pre-title default, and again when a button
is pressed. `TouchInput.available()` can be read once because hardware does not change; the player's
answer arrives long after the node is in the tree.

**Pressing a disc is the only way a pointer begins a run**, which is what turns M85's ending-screen
leak from a race into a much smaller one. **The 0.35s restart guard was kept rather than deleted
with the headline defect**: a stray press can still land on a disc.

**`is_forced()` was deliberately not restored.** It used to hide the buttons when `--controls` or
`?controls=` had already answered — *"a flag is how you skip the question"*. With the buttons as the
unconditional way in there is no exception to carve, so `ControlsMode.resolve()` now answers only
the pre-title default a rig gets when it skips the screen with `--no-title`. **That default is
`TAP`**, so every existing screenshot and `--walk` script reproduces under the mode it was taken in.

**`Symbol.JOYSTICK` and `Symbol.TAP` are appended after `RESTART`/`CONTINUE` rather than restored to
their old indices.** The enum's ints are serialised into `scenes/ui/day_summary.tscn` and
`pause_screen.tscn` as `symbol = N`, and nothing in the suite constructs a `ModeButton` from its own
scene file — M82 caught that re-indexing only with a screenshot. Appending makes it a non-event.

**Two things a screenshot caught that no test could.** The hint under the buttons still read
`tap to begin` while a bare tap no longer began anything — a screen instructing a first-time player
to do the one thing that would not work; it now reads `press a button to begin` / `press a button to
walk again`. And the two columns were `alignment = 1` (centre), so captions of different line counts
put the two discs at different heights; both are top-aligned now, which survives any future reword
rather than depending on two captions staying the same length.

**The teaching line was assessed and deliberately left alone.** `Tap to walk, double tap to run.` is
what playtest 33 asked for in those words and it is true in both modes — the difference between them
is *where a press is measured from*, which the two drawn circles say in joystick mode and the two
title captions say once.
