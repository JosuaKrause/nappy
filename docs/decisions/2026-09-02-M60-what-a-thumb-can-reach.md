## M60 — What a thumb can reach · built 2026-09-02

**Every lesson the game teaches named a key.** The run hint said *Hold SHIFT to run* on a phone,
found by playing the deployed build. The audit that followed — *"check all tutorial lines for mobile
versions"* — found exactly two more lines with no touch form: the day-1 walk lesson and the pause
lesson. **The negative half is the useful half**: the title and pause bodies, and every
*space*/*tap* hint on the title, the pause screen and the between-days summary, already chose their
wording from `TouchInput.available()`, and *q to quit* already appeared only where
`QuitOption.available()` says quitting does something. Recorded so nobody audits those screens again
to find nothing.

**The wording matches the control rather than inventing a name for it.** *Hold RUN to run* reuses
the pause screen's existing touch body character-for-character, and *Drag the stick to walk* does
the same, so two screens never call one control two things. The pause lesson says *Tap the pause
button to pause* — a description, because the button is drawn as two bars with no text on it, and a
line quoting a label that is not on screen is the defect the whole audit exists to fix.

**The pause button is the one control that cannot press its action.** The stick and the `RUN` circle
call `Input.action_press`, and `main._unhandled_input()` reads the pause off the propagated *event*
— so pressing the action would set the state and be heard by nothing. It sends an `InputEventAction`
through `Input.parse_input_event()`, the shape `tests/test_pause.gd` already builds by hand. It
fires on a clean release inside the button rather than on touch-down, so a thumb that lands wrong
can slide off without stopping the day. **A first test failed for the honest reason**: it asserted
polled `Input` state after sending an event, which is not set synchronously.

**Placed at (1250, 30) with a 26px disc and a 46px catch** — small, because it is pressed once a day
at most, unlike the stick's 60px reach and 100px catch. The two other things that live near an edge
were checked rather than assumed: the screen-edge danger badges, and `HomeArrow`, which draws no
closer than (1206, 74) while hugging an edge.

**The meters move to the top left on touch only.** *(2026-09-02: "let's also move the progress bars
to the top for mobile so they're not hidden by the finger.")* The bars sat 18px above the bottom
edge, which is the quietest corner of a desktop screen and the busiest part of a phone. The anchors
move on the one node rather than a second HUD scene existing to be changed twice forever; the
desktop layout is untouched, since nothing is in front of it there.

**Landscape is asked for, not enforced, because it cannot be.** *(Wrong, and corrected on
2026-09-05: the instruction was to make the game always **do** landscape, and it was answered with a
message asking the player to rotate the phone. Two of the three available levers were never used —
the manifest is not written because the PWA export is off, and the lock is called outside the
fullscreen and gesture it requires — and the third, rotating the canvas in portrait, is what makes
it universal. The item is in `TODO.md` under M60.)* `progressive_web_app/orientation=1`
is only read from an installed PWA manifest, which this build does not write. So `html/head_include`
carries a `screen.orientation.lock('landscape')` attempt — wrapped so a rejection or a missing API
is silent, since Chrome for Android needs fullscreen for it and iOS Safari has no such API — and,
because that lock cannot be relied on, a CSS overlay that asks. It keys on `orientation: portrait`
**and** `hover: none` **and** `pointer: coarse` together, so a narrow desktop window is never told
to rotate.
