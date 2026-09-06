# Playtest 26 — 2026-09-06

The first session on the build that asks which controls, given as notes in one conversation.
**Four findings, and they are one complaint wearing four hats**: every screen in this game states
its controls as a sentence, and a sentence is not a control. The title screen's choice, the day
summary's dismissal and the missing restart are all the same shape — the game says what to press
where it should offer something to press.

**Nothing here is diagnosed.** One of the four contradicts what the code says outright, and that is
recorded as the contradiction rather than resolved into a cause.

---

## 1. The controls choice on the title screen is not obvious, and wants proper buttons

> "the choice on the title screen is not at all obvious. those should be proper buttons"

The two choices **are** `Button` nodes already — `Stick` and `Tap` under
`Root/Bottom/Lines/Choice` in `scenes/ui/title_screen.tscn`, each 380x100 with a 15px font. What
they are not is *drawn* as buttons: the scene gives them a minimum size, a font size and wrapping,
and nothing else, so they inherit Godot's default flat theme and sit on the title's scrim looking
like the three lines of label text directly above them.

So this is not "add buttons", it is **"the buttons do not read as buttons"**, and the fix is a
visual one on a screen that currently has no visual vocabulary for a control at all. Nothing else
in the game draws an interactive control except `TouchControls`, which draws its stick, `RUN` and
pause with its own `_draw()`.

## 2. On the desktop, the input you choose with should be the input you play with

> "on the local clicking should choose the tap and arrow keys should choose the controls (we can
> keep space too I guess -- t I'm not so sure since it's a move from keyboard to mouse)"

The principle underneath it is stronger than the two mappings, and it is the player's own: **the
device you answer the question with is the device you are answering about.** Clicking a button is
what tap-to-walk *is*, and pressing an arrow key is what the stick scheme *is* on a desktop, so
each choice can be made by doing the thing it selects. Nothing has to be read for that to work.

What the screen does today, in `TitleScreen._unhandled_input()`:

- `ui_accept` — which is `space` and `enter` — chooses **stick**.
- `t` chooses **tap**, and the hint reads *"space or t to choose"*.
- A screen touch anywhere chooses **stick**.
- A click that lands on either button chooses that button's mode, through the `Button`'s own
  `pressed` signal.

So a click already works where it lands on a button, and the requested change is that **a click
anywhere** means tap-to-walk, and that **the arrow keys** — which today do nothing on this screen —
mean the stick.

**`t` is left open by the player rather than decided.** *"t I'm not so sure since it's a move from
keyboard to mouse"* — the objection being that `t` is a key that selects the scheme you play with a
mouse, so the hand that answers the question is the wrong hand for the answer. That is the same
principle as the rest of the finding and it points at dropping `t`, but the player said they were
unsure, so it is written down unsure. **Space is kept** — *"we can keep space too I guess"* — and
under the principle it means the stick, which is what it already does.

## 3. On the phone, a summary has to be tapped on its text, and that contradicts the code

> "on mobile when the day ends or one dies you have to tap on the text right now I should be able
> to tap anywhere or it should be obvious where I need to tap"

**Tap-anywhere is what `DaySummary` is already written to do.** `_unhandled_input()` takes any
pressed `InputEventScreenTouch`, with no position test of any kind, and emits `continued`. There is
no region check to loosen.

**And nothing obvious is eating the touch first.** Both touch handlers run at the `_input` stage,
which is ahead of `_unhandled_input`, so either could swallow it — but neither calls
`set_input_as_handled()` anywhere in its file, so both leave the event to travel on.
`TouchControls._input()` also returns immediately when it is not visible, and it is not visible over
a summary.

So the first half of this item is **finding out what actually happens**, not designing the fix: a
report that contradicts the source means the cause is somewhere nobody has looked, and the fix
depends on which. The player's own second clause — *"or it should be obvious where I need to tap"* —
is the design if the answer turns out to be that tap-anywhere is undiscoverable rather than broken,
and it is the same want as finding 1.

## 4. There is still no restart button

> "and there is no restart button still"

**"Still" is right, and this is a re-report of something already designed and not yet built.**
`docs/TODO.md` under M60 holds *"A phone cannot start the run again, and wants a button on the pause
screen that can"*, from *(2026-09-05: "we need a dedicated button for restart from the pause
menu")*, specified down to the interaction — a **hold** that fills over about a second, chosen over
a one-tap button and over arm-then-confirm, labelled `hold to restart`, and tested against the touch
position before the catch-all that treats any touch on the pause screen as *carry on*.

**What this session adds is where it was missed.** The sentence arrives alongside the day-ending and
death screens rather than the pause screen, and those are a second place the want lands: the ending
offers *"tap to start again"* and a lost day offers *"tap to go on"* or *"tap to try again"* — all
of them sentences, none of them a button, which is finding 1 again. Whether the queued pause-screen
hold is the whole answer or whether the summary needs its own control is open.

---

## The design, given when the two open questions went back

Both were asked in the same session the findings were recorded in, before anything was built.

**A button is interface, not art.** Asked whether finding 1's *"proper buttons"* counted as drawing
work:

> "this is not game graphics. buttons are just UI"

**`t` is dropped.** The player closed their own uncertainty from finding 2 by taking it out, which
leaves the principle without an exception: click chooses tap, the arrow keys choose the stick,
`space` stays and means the stick. No key selects the scheme played with a mouse.

**The title's two buttons carry symbols for the mode they select:**

> "build buttons with symbols indicating the mode (joystick for keyboard controls and something
> else for taps)"

A joystick for the stick scheme, and something yet to be chosen for tap-to-walk.

**And the day-end and pause screens get the same pair of buttons as each other:**

> "on the day end and pause screen show two buttons continue (arrow to the right maybe?) and
> restart game (must be held down so a bar needs to fill up while pressing; maybe a circular
> arrow?)"

That settles the question finding 4 left open — whether the queued pause-screen restart was the
whole answer, or whether the summary needed a control of its own. **It is both screens, with one
pair of buttons**, so there is one interaction to learn rather than two.

**Continue** is an arrow to the right, offered as a suggestion rather than a decision. **Restart**
is held rather than tapped, with a bar that fills while it is pressed, and a circular arrow for the
symbol — again suggested. The hold is what M60 had already specified for the pause screen after
weighing it against a one-tap button and an arm-then-confirm second tap; this repeats it
independently and extends it to the summary.
