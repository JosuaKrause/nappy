# Playtest 35 — 2026-09-07

The first session played on the M90 controls and the first look at M89's halo, given as notes in
one conversation. **Seven findings and one answered question.** Four are about the controls M90 had
just fixed — three of them about work M90 itself introduced — one settles a question M89 left open,
one asks for a size, and one is parked by the player on sight.

**Neither milestone had merged when this was reported, so all five are built inside them** rather
than queued: M90's four on `feature/the-controls-do-what-the-hand-does`, and finding 5 on
`feature/a-halo-says-what-is-costing-her`. Nothing merges carrying a defect that was already
found.

---

## 1. The stop circle is at her feet, not around her

> "the stop circle for the player is at her feet -- should be at the center of the sprite -- right
> now I can click below her to stop."

**Confirmed, and it is the game's own anchoring rule showing through a cue that should not have
inherited it.** `Sprites`' doc states it plainly: *"Everything in this game stands on the ground
plane: a node's position is where its feet are, and its art rises from there."* So
`Stroller.global_position` is the pavement under her shoes, and `TouchControls._near_her()`
measures `TAP_STOP_RADIUS` (24 world px, set by playtest 34 finding 5) from that point.

She is drawn 24x46, feet-anchored, so:

| | relative to her feet |
|---|---|
| the circle as it is | −24 to **+24** — a full 24px of pavement *below* her |
| her actual silhouette | 0 to −46 |
| her head | −46, **outside the circle entirely** |

So a press on the ground below her stops her and a press on her head does not, which is exactly
backwards. **Measured from the middle of the sprite (23px up, half its drawn height) the same 24px
radius covers her from the shoes to the shoulders and stops one pixel below her feet** — no new
number needed, only a centre.

**This is the same defect the halo had**, and it was fixed there by tracing the sprite instead of
placing a shape near it. Here a circle is right; only its centre was wrong.

## 2. The restart button's press fill fights its own hold sweep

> "the light up of the reset button conflicts with the bar filling up."

`ModeButton` draws two things for `Symbol.RESTART` now. The radial sweep that fills while the
button is held is translucent white (`_HOLD_FILL`, alpha 0.4) over the disc, and M90 added
`Palette.BUTTON_PRESSED` — a near-white `(0.95, 0.93, 0.88, 0.95)` — as the pressed fill underneath
it. **A pale sweep over a pale disc has nothing to read against**, so the one control in the game
that shows progress stopped showing it.

**Resolved by handing over rather than by choosing one** *(2026-09-07, the player, choosing between
three offered options: "Pressed fill only until the hold starts")*: the disc flashes pressed on
contact, which is the acknowledgement every other button gives, and then drops back the moment
`begin_hold()` starts the timer, leaving the sweep alone on the resting disc for the whole of the
hold. Both cues keep their meaning and neither is drawn over the other.

## 3. Hover is halfway to pressed, not a shade of brown

> "make the hover white more subtle (50% transparent compared to the full click)."

The three fills are one hue and the hover step is nearly invisible against the resting one:

| | now | |
|---|---|---|
| `BUTTON_FILL` | `(0.18, 0.15, 0.13, 0.88)` | resting |
| `BUTTON_HOVER` | `(0.24, 0.2, 0.17, 0.92)` | a slightly lighter brown |
| `BUTTON_PRESSED` | `(0.95, 0.93, 0.88, 0.95)` | near-white |

**The asked-for hover is halfway between resting and pressed**, so the two states become one scale
rather than a brown pair and a white outlier — half the white, read against the same fill. That is
`(0.57, 0.54, 0.51, 0.92)`, the midpoint of `BUTTON_FILL` and `BUTTON_PRESSED`.

## 4. Crossing the middle retargets to the other joystick

> "dragging from one side of the screen to the other side of the screen keeps the reference on the
> original side. this might make sense were it not for the stop gap in the middle. since there is a
> gap in the middle that stops I think we should retarget to the other side when that happens."

**The player's reasoning is the whole of the design, and it resolves a decision M85 took for a
reason that no longer applies.** M85 made `nearer_focus()`'s choice stick for the length of a drag
because the focus otherwise flipped the instant a pointer crossed the design box's centre line,
swapping a heading measured from `FOCUS_LEFT` (240, 480) for one measured from `FOCUS_RIGHT` (1040,
480) and snapping back and forth while the thumb barely moved. Its own note says so: *"Hysteresis
and a stickier focus were the obvious answers and are recorded as rejected: declaring the middle
not-a-direction removes the flip rather than damping it."*

**The stop band is what makes retargeting safe now.** A pointer cannot cross the centre line
without passing through `STOP_RADIUS` (48px) either side of it, and inside that band she is
stopped — so a crossing is already a discrete, deliberate event with a defined state in the middle,
not a continuous slide between two references. There is nothing left to flip-flap between.

So: while the pointer is in the band she is stopped, exactly as now; **when it leaves the band, the
focus is chosen again for whichever side it left on**, and the drag continues from there. The
sticky-for-the-whole-drag rule survives everywhere else, which is where it was earning its keep.

## 5. The halo does not trace the shadow

> "the halo should not include the shadow"

**Answers the one question M89 left open.** `EventInstance._draw_halo()` re-runs that entity's own
`_draw_body()` at a ring of offsets, and `_draw_body()` draws the drop shadow first — so the
shadow's ellipse was picked up and outlined along with the silhouette, putting a soft amber lobe on
the ground beside every glowing entity. Seen on the leaf-blower capture the cue was signed off
from.

The halo pass skips the shadow. Everything else about the trace is unchanged.

## 6. The movement lesson is twice the size

> "can you double the size of the tutorial text?"

**Three labels, not one**, because the lesson appears in three places and only one of them is read
while walking: the title screen's body and the pause screen's body (16pt), and `HUD`'s own `Teach`
line during play (19pt). All doubled.

**The HUD line needed its box grown as well as its font.** It is a fixed rect rather than a
container child — 520x30 — and "Tap to walk, double tap to run" at 38pt is wider than 520, so it
would have clipped. It is 1040x60 now, still centred on the bottom edge. Its outline goes 6 to 12
in step, because an outline sized for 19pt reads as a smudge under 38pt, and this is the one lesson
drawn over a moving street rather than over a panel.

## 7. The buttons are rounded rectangles, not circles — parked

> "the hover highlight showed a bug that the button is currently a square and not the circle --
> although nothing we need to fix right now"

**Parked by the player on sight, and recorded so it is not rediscovered.** `ModeButton._disc_style()`
sets every `corner_radius_*` to `_RADIUS` (46), which renders a circle only while the button's rect
is exactly 92x92. `custom_minimum_size` is a *minimum*, so any container that stretches the button
wider leaves a rounded rectangle instead.

**It has always been true; the hover fill is only what made it visible.** The resting and hover
browns were close enough to the panel behind them that the corners did not read, and a near-white
hover shows the silhouette outright. **So this is not a regression from the hover change** — it is
an old defect that the hover change exposed, which is the more useful half of the finding.

---

## The question: does the dog ever give up while she walks?

> "the pursuing dog should never stop pursuing when I walk is that the case? I checked and I
> couldn't walk away but I wanted to make sure"

**Answered from the code: no, walking can never end a chase.** `EventInstance._chase()` gives up on
exactly one condition — `_outrun_for >= Tuning.PURSUIT_SHAKEN_OFF` (0.35s of the gap *opening*) and
`chase_age() >= Tuning.PURSUIT_MIN_NOTICE` (1.5s, the floor that stops a chase ending before it was
a threat). A pursuer runs at 130px/s against `WALK_SPEED` 92, so walking always closes the gap and
`_outrun_for` never accumulates; only `RUN_SPEED` (168) opens it. The code says so in as many
words: *"Walking away cannot end a chase at any distance, and running away always ends one in
`Tuning.PURSUIT_SHAKEN_OFF` seconds regardless of how big the thing chasing her is."*

**One margin was raised as a risk and accepted.** *(2026-09-07, on being shown it: "getting lucky
once is fine.")* A chase still ends when the row's own clock runs out — `telegraph_time + duration`,
4.5s + 3.0s after M91 — and M91 sized the telegraph so that walking away still loses inside that
window, closing the worst-case gap at `pursue_speed - WALK_SPEED` (38px/s) in about 7.0s against
7.5s available. **That is half a second of margin**, so on the worst siting geometry a walking
player could outlast the clock rather than being caught. The player's own reading is that a rare
escape is not a defect; it is written down here so that a future report of *"the dog gave up and I
never ran"* is recognised as this and not as a new bug.
