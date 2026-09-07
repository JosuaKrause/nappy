# Playtest 34 — 2026-09-07

A session on the build M88 left, played on a laptop and given as notes in one conversation. **Ten
findings.** Six are about the controls M88 shipped — a button that never changes when it is pressed
or hovered, a stop circle twice the size of the one it is supposed to match, a press on the pram
that stops her, and three separate ways the joystick's drag does not do what the hand does. Two are
about how much notice a pursuer gives, in opposite directions. One is about which side of the road
the biker arrives on. One renames the two modes and deletes their captions.

**Two of these are re-reports, and both matter for that reason.** Finding 1 asks again for something
[PLAYTEST-33.md](PLAYTEST-33.md) finding 5 asked for and this project recorded as built; finding 2
uses the word *"still"* about a lead time [PLAYTEST-20.md](PLAYTEST-20.md) already measured. Neither
is a new request and neither should be designed again from scratch.

---

## 1. The mode buttons never light up, pressed or hovered

> "buttons still don't light up when pressed or hovered."

**"Still" is accurate and this is a re-report of a fix that changed the wrong half.** Playtest 33
finding 5 said *"buttons should light up white when pressed"*, and what M85 changed was the colour:
`Palette.BUTTON_PRESSED` went from `(0.11, 0.09, 0.08, 0.95)`, darker than the resting fill, to
`(0.95, 0.93, 0.88, 0.95)`, near-white. That colour is correct and it is never reached.

**`ModeButton` sets `mouse_filter = Control.MOUSE_FILTER_IGNORE` in `_ready()`, and a `Button` that
ignores the mouse never enters its own hover or pressed state.** The three styleboxes
`_apply_disc_style()` installs — `normal` at `Palette.BUTTON_FILL`, `hover` at `BUTTON_HOVER`,
`pressed` and `hover_pressed` at `BUTTON_PRESSED` — are switched between by `Button`'s internal
draw mode, which is driven by mouse events the control is filtered out of. So all three exist, are
the right colours, and only `normal` is ever drawn.

**The `IGNORE` is load-bearing and must not simply be reverted.** Its own comment records why it is
there, from playtest 29 finding 2 (*"the buttons do not work at all... the buttons themselves do
nothing"*): Godot's GUI layer runs between `_input` and `_unhandled_input` and consumes a raw
`InputEventScreenTouch` that lands on a control whose `mouse_filter` is `STOP`, and `PauseScreen`,
`DaySummary` and `TitleScreen` all read every press in `_unhandled_input()`. A button that claims
the event is a button whose screen never hears the press. **So the pressed and hover looks have to
come from the same raw-touch reading the screens already do** — the screens already know which
button a press landed on, through `ModeButton.catch_rect()` — rather than from `Button`'s own state.
`force_pressed_look()`/`clear_forced_press()`, which `DaySummary` already uses to flash a disc for a
press that landed elsewhere on the screen, are the shape that exists for this.

**Hover has never been asked for before and is new here.** It is a laptop's question — there is no
hover on a phone — and `MOUSE_FILTER_IGNORE` also means no `mouse_entered`/`mouse_exited` at all, so
whatever answers the press has to answer this too.

## 2. The pursuing dog is still too short notice

> "pursuing dog is still too short notice"

**A re-report, and the older entry has the measurement in it.** `docs/TODO.md` carries an open item
*"The tutorial dog is not a tutorial after day 3"* with playtest 20's figures under it: across five
`charging_dog` encounters in one seven-day run, every encounter that ended in evasion ran 1.5
seconds from the chase starting to the dog giving up, while the two that killed her ran 0.8 and 0.9
seconds, with the day-4 encounter's telegraph closing roughly 70px in 0.3s against the tutorial
encounter's 20px in 1.1s. That item reads the gap as most likely a placement effect rather than
row tuning, and names the item above it as the first thing to check.

**What is new is that M87's offscreen siting did not fix it.** `Tuning.offscreen_lead(heading,
closing_speed)` now sites a pursuer outside the view plus `OFFSCREEN_NOTICE` (0.2s) of closing, and
for `charging_dog` at 130px/s closing at 222px/s that 200ms buys 44px. **44px of extra approach is
what "still too short" is measured against**, so the number to move is the notice itself for this
row rather than the siting rule that delivers it.

## 3. The biker is now too long notice

> "while biker is now too long notice"

**"Now" is accurate: this is M87's own arithmetic working as designed and overshooting.**
`Tuning.outlasting_telegraph_lead()` takes whichever is further, the ordinary offscreen margin or
`(telegraph_time + OFFSCREEN_NOTICE) * closing_speed`. `cyclist` carries `telegraph_time` 3.3s and
closes at 257px/s (its own 165px/s plus `WALK_SPEED` 92px/s), so the telegraph term is 900px against
a 371px offscreen margin and it is the binding one. The biker is therefore sited nearly a thousand
pixels out — against a visible world of 640x360 at zoom 2 — and the player watches it coming for
over three seconds.

**M87 recorded shortening the telegraph as rejected, and this finding is the player reversing that.**
The note in `DECISIONS.md` says shortening it *"buys the lethality back by taking the notice away,
which is the complaint the rest of the milestone is about"* — the complaint at that time being too
*little* notice. **The complaint has flipped for this row and only this row**, so the rejection's own
reasoning no longer applies to it. What must not change is the constraint that produced the 900px in
the first place: `EventInstance.is_lethal_at()` returns false for the whole of `is_telegraphing()`,
so a biker that arrives before its telegraph ends is declared `hard_fail` and cannot hurt her. **The
telegraph and the siting are one number, and any shortening has to keep the arrival after the
telegraph ends.**

## 4. The biker comes down the far side of the road

> "also biker should be on the same side of the road not the other side"

`cyclist`'s `placement` is `[SIDEWALK, SQUARE]` and its `spawn_mode` is `TOWARD_PLAYER`, so the
siting picks a sidewalk tile the required distance out along her heading and nothing in it prefers
*her* sidewalk over the one across the carriageway. **The complaint is about what the encounter is
for**: a biker on the far pavement is scenery, because the road between them is already a thing she
does not cross casually, and the whole content of the row is *get out of its lane*.

## 5. The stop circle on her is twice the size of the joystick's

> "the stop circle on the player should exactly be the size of the joystick stop circle nothing
> bigger."

**Confirmed by arithmetic, and the cause is that one constant is compared in two different spaces.**
`TouchControls.STOP_RADIUS` is 48.0, and it is used for both:

- in `Mode.JOYSTICK`, `is_on_a_focus()` and `is_in_stop_band()` compare it in **design space**, so
  the ring `_draw_focus_circles()` draws at `STOP_RADIUS` is 48 design px and the door is exactly
  the drawn circle;
- in `Mode.TAP`, `_on_tap()` compares `world.distance_to(_rig.global_position) <= STOP_RADIUS` in
  **world space**, and the camera sits on her at zoom 2 — so 48 world px covers 96 design px on the
  glass, twice the drawn ring.

The asked-for size is the joystick's: the same number of pixels on screen either way, which at zoom
2 is 24 world px around her.

## 6. A press on the pram is not a press on her

> "if I click on the stroller it shouldn't stop only when I click on the body of the player."

**This overturns a reason written beside the constant.** `STOP_RADIUS`'s own doc argues it is
*"wider than `Tuning.PLAYER_BODY_RADIUS` (14px) alone — the pram rides up to `PRAM_DISTANCE` (34px)
off to one side of her, and a press that lands on the pram is a press on her"*. The player is saying
the pram is not her.

**It resolves cleanly with finding 5 rather than fighting it.** 48 design px at zoom 2 is 24 world
px, which is comfortably clear of `PRAM_DISTANCE` (34px) and still generous against
`PLAYER_BODY_RADIUS` (14px) — so the smaller circle finding 5 asks for is also the circle that
stops covering the pram. One number answers both.

## 7. Only the joystick on the side she is pressing is the reference

> "the two joysticks are broken when I'm on the left side only the left joystick should be used as
> reference and on the right side only the right one"

**What is described is already what `nearer_focus()` computes**, and that is why this is worth
checking rather than building: `FOCUS_LEFT` (240, 480) and `FOCUS_RIGHT` (1040, 480) share a `y`, so
"nearer" reduces to which side of the design box's centre line the press is on. **So either the
selection is right and something downstream makes it feel wrong, or the press never reaches it with
the coordinates it expects.**

**The most likely candidate is finding 9's drift, and it would produce exactly this symptom**: the
focus chosen at the press is stored as a *world* point for the rest of the drag, and the camera
moves under it, so the reference slides away from the circle under the thumb and can end up on the
far side of her. **Check finding 9 first, and only treat this as its own defect if it survives.**

## 8. A drag out of a joystick's centre does nothing

> "when I start dragging from the center of the joystick nothing happens it should behave the same
> as if I move to the center and back stop while I'm in the center and move when I'm back."

**Confirmed, and the cause is one line.** A press inside `STOP_RADIUS` of a focus goes through
`_stop()`, which leaves `_walking` false; `_on_pointer()` then only takes the drag index when
`_walking` is true — its comment says so, *"a stop leaves `_walking` false, so a press on her, on a
focus, or in the stop band never starts a drag that would only re-open the direction it just
closed."* So a finger that lands in the middle of a circle is not tracked at all and every motion
event after it is discarded.

**The asked-for behaviour is stated exactly and it is the behaviour a drag that starts outside
already has**: a pointer in the centre means stopped, a pointer out of it means walking that way,
and crossing the boundary in either direction changes it live. The rule to delete is "a stop does
not start a drag", not the stop itself.

## 9. A drag does not follow the pointer

> "not sure what exactly the issue is right now but I cannot drag around the joystick circle and it
> follows the whole way. it moves a bit and then moves completely differently from what my movement
> is"

**"Moves a bit and then moves completely differently" is the shape of a reference point drifting,
and there is one that drifts.** `_on_tap()` converts the chosen focus to world space once —
`_drag_origin_world` — and `_on_drag()` measures every subsequent heading from that stored world
point. **A focus is a fixed place on the glass, not a place in the city.** The moment she starts
walking, the camera moves with her and the world point that was under the drawn circle is left
behind in the street. Early in a drag the two are close and the heading tracks the thumb; a second
later the reference is somewhere off behind her and the heading points somewhere the hand never
asked for.

**So the origin has to be recomputed per motion event rather than captured at the press**, which is
the same design→presented→world trip `_on_tap()` already makes, done each time instead of once.
That is not the analog stick returning: `set_direction()` still normalises every heading, so
`tests/test_touch.gd`'s `_test_no_input_path_presses_a_vector_shorter_than_one` is unaffected.

**This is very likely the whole of finding 7 as well**, and possibly part of what makes finding 8
feel worse than it is.

## 10. The two modes are named and not explained

> "the explanations for the two modes are very convoluted simplify them and focus around how they
> make things different not implementation details"

> "also don't mention stopping"

> "call the modes 'On-screen Controls' and 'Tap to Go' no further explanations"

**Three sentences arriving in that order, and the third is read as replacing the first two**: it is
later, it is strictly narrower, and *"no further explanations"* leaves nothing for *"simplify them"*
or *"don't mention stopping"* to apply to. The captions become the two names and nothing else.

| | now | asked |
|---|---|---|
| `Mode.JOYSTICK` | a caption explaining the two focal points | **On-screen Controls** |
| `Mode.TAP` | a caption explaining aiming from her | **Tap to Go** |

**The teaching line under the buttons is a different sentence and is not what this asks about.**
`Tap to walk, double tap to run.` is what playtest 33 asked for in those words, it is true in both
modes, and nothing here names it.
