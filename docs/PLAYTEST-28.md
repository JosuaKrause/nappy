# Playtest 28 — 2026-09-06

The third session on the released page and the second of the day, played on a laptop browser
against `v0.4.1`, given as notes in one conversation. **Three findings, all of them about the
scheme the player calls *mouse mode*** — the tap scheme, chosen with the tap button and played
with a mouse rather than a finger.

One is a thing that is wrong. Two are a design: what mouse mode should do instead of what it does,
and the control it needs once it does that. **Four more specifics came back in the same session,
in answer to questions asked before anything was built**, and between them they make this the
largest change to the controls the project has made — there is one scheme now. They are in
*The four answers* below, and each is quoted where it lands.

**All three are diagnosed from reading the source, not from instrumenting the released build.**
Where a claim comes from reading it is said so in the finding.

---

## 1. Space is still the only way past a screen on a laptop

> "also one thing on laptop -- I still need to press space even in mouse mode."

**Every screen in the game accepts exactly two things, and a mouse click is neither.**
`TitleScreen._unhandled_input()`, `DaySummary._unhandled_input()` and
`PauseScreen._unhandled_input()` all test `event.is_action_pressed("ui_accept")` — which is `space`
and `enter` — or an `InputEventScreenTouch` press, which is what a real finger sends. A laptop has
no touchscreen, so on a laptop the second branch can never fire and the keyboard is the only way
off the day summary, off the ending, and out of the pause. **This is true in both control schemes**,
which is why it is a separate finding from playtest 27's second one rather than the same one again:
it is not about walking, and fixing tap mode's walking would not touch it.

**The game says so itself.** `DaySummary._update()` sets the hint from
`var verb := "tap" if _touch else "space"`, so a laptop is told *"space to go on"* — the screen is
describing the input it actually has, accurately, and the player is reporting that having chosen a
pointer scheme they still have to reach for the keyboard.

**The one exception is the title screen's two buttons**, and it is why the run can be started at
all: the joystick and tap discs are real `Button` nodes whose `pressed` signal is connected in
`TitleScreen._ready()`, so Godot's own GUI input handles a click on them before
`_unhandled_input()` ever sees it. Every other screen in the game has nothing to click.

**Accepting a click here overturns a written reason, and the player's own words are what overturns
it.** The comment above `DaySummary._unhandled_input()` says the touch event is read directly
*"rather than turned into a synthetic click, so a stray mouse press elsewhere on the desktop still
cannot skip a summary a player has not read"* — a real concern about a misplaced click eating a
screen, taken when no scheme invited a player to use the mouse. Tap mode now does invite it.

## 2. Mouse mode should walk in a direction indefinitely, not to a point

> "and let's do mouse mode to behave the same way that she keeps walking in the direction
> indefinitely"

**"The same way" is playtest 27's sixth finding**, the aimed joystick that replaces the drag stick:
a press is read as a *direction*, that direction is locked in, and she walks it with nothing held
down until another press changes it. The player is asking for mouse mode to work the same way.

**This replaces the whole of tap mode's current design, which is a destination rather than a
heading.** `TapControls` today fixes a heading at the tap *and a target*, walks the straight line,
and stops: `has_arrived()` is `(target - position).dot(direction) <= 0.0`, the plane through the
target at right angles to the heading, and crossing it releases the movement actions. Under this
finding there is no target and nothing to arrive at — she walks the heading until the next press.

**Two written decisions are inside what this replaces**, both from 2026-09-05 and both recorded in
`docs/TODO.md` under the tap-mode entry, so neither can be dropped quietly:

- **The straight line to a location** is the definition the mode was asked for with: *"tap mode is
  'I click on the screen and then the player moves to that location on a straight line'"*.
- **The arrival pause**: *"when the player reaches a location and stops movement — normally the
  pause hint would show up — in this mode it just pauses"*, with the 5-second delay the player
  specified after it (*"the 5s timer should start after arrival"*). It is `ARRIVAL_PAUSE_AFTER`
  (5.0 seconds) in `TapControls`, and it is armed by arriving. **Nothing arrives any more under
  this finding, so that clock can never start** — which is exactly why finding 3 exists.

## 3. Mouse mode needs the pause button in the top right

> "and then it also needs the pause button in the top right"

**This follows from finding 2 and the player drew the line themselves** — the *"and then"* is the
argument. Tap mode has no pause button today, and that was a decision rather than an omission:
*"tap mode is … this mode does not have UI elements"*, recorded in `docs/TODO.md` as **no stick, no
`RUN`, and no pause button** — *"the whole screen is the control, so there is nothing on it to catch
a thumb, and every pixel of the city is a destination rather than a place a hidden button might
be."* The pause it did have was the arrival clock: **no pause button is needed, because arriving is
the pause.**

Finding 2 removes arriving. So the mode loses its only way to pause on a device with no `Esc` key,
and the button is what puts one back.

**Top right is where the other scheme's already is**, which is what makes it the same control rather
than a new one: `TouchControls.PAUSE_CENTRE` is `(1218, 62)` in the 1280×720 canvas, drawn as a
26px-radius disc with two bars, and pressing it calls `TouchControls._send_pause_action()` — a real
`InputEventAction` for `pause` pushed through `Input.parse_input_event()`, so it arrives at
`main._unhandled_input()` exactly the way `Esc` does. `TapControls` already sends that same action
when its arrival clock expires, so the mode is not gaining a new mechanism, only a place to press.

**And it costs the thing the no-UI decision was protecting.** Every pixel of the screen being a
direction was the point; a 26px disc in the corner is now a place a press means something else.
Playtest 27's sixth finding already accepted that trade for the joystick scheme — it reads the left
two thirds of the screen and leaves the pause *"still in the top right"* — so the corner is already
spoken for there, and this makes the two schemes agree.

---

## The four answers

Four things the notes did not settle went back to the player before a line was written, and all
four came back in the same session. Two of them are much larger than the question that asked them.

### It applies everywhere, not only to the mouse

*(2026-09-06, asked whether "keeps walking indefinitely" meant a finger on a phone too or only a
mouse on a laptop: **both — tap mode changes everywhere**.)*

So there is one behaviour rather than a branch on whether the device has a touchscreen. The
straight-line-to-a-location design and the 5-second arrival pause are gone on every device, not
only where a mouse is driving.

### Every other mode is deleted

> "get rid of all other modes"

*(2026-09-06, asked whether the aimed joystick and the tap scheme stay as two comparable schemes or
merge into one.)*

**This is the largest of the four and it repeals more than the question asked about.** What goes:

- **The drag stick**, `TouchControls`' gripped on-screen stick — already condemned by playtest 27's
  sixth finding, which replaced it with an aimed joystick. It is now deleted without a replacement
  scheme rather than with one.
- **The aimed joystick itself**, playtest 27's sixth finding, which was specified in full and never
  built. Its walking rule survives — press, direction locked in, walks until something changes it —
  but not as a scheme of its own: **no stick is drawn, and the direction is measured from her
  rather than from a drawing's centre**, because with nothing drawn there is no centre to measure
  from. Its 24px stop target at the joystick's centre is replaced by the stop below.
- **The controls question on the title screen**, which exists only because there were two schemes to
  choose between. With one scheme there is nothing to ask, so the two circular mode buttons go and
  the screen returns to a single "press to begin".

**The keyboard is not a mode and stays.** Arrows and `WASD` press the `move_*` actions directly and
always have, on every scheme, and nothing in the notes touches them; `Shift` to run and `Esc` to
pause stay with them. If that reading is wrong it is the one thing here worth saying so about,
because it is a device rather than a scheme.

### Stopping is a click on her

> "also, to stop her just click on her"

**This replaces playtest 27's stop target**, which was a 24px tap area at the drawn joystick's
centre — a control that cannot survive the drawing being deleted. Stopping is now a press on the
player herself, which is a place that exists in every scheme and needs nothing drawn to find.

It also replaces what stopped her before: arriving. `TapControls.has_arrived()` — the plane through
the tapped target at right angles to the heading — is what released the movement actions, and with
no target there is nothing to arrive at.

### Running is a double press

*(2026-09-06, asked how she runs once the stick's held RUN button goes with the stick: **double
press keeps running**.)*

The double press is what tap mode already reads — `DOUBLE_TAP_SECONDS` (0.35s) decides *soon
enough* and `DOUBLE_TAP_DISTANCE` (60px) decides *close enough to the first press to mean the same
thing* — and it now sets a direction *and* runs it, holding the `run` action until the next press
changes the direction or stops her. **The held RUN circle at (1150, 500) goes with the stick**, so
nothing is drawn but the pause button.

---

## Sequencing

> "do those before merging"

These come before PR #26 (`feature/screens-press-back`, M76's continue and restart buttons), which
is open, green and cleanly mergeable and is not to be merged until they are built.
