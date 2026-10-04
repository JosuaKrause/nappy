# freckled-lemur — A help text shows the button it means · built 2026-10-04

*([misty-toad](../playtests/2026-10-04-misty-toad.md), inbox #533: "For example the press pause to
pause text should say press \<pause button\> to pause where it uses the in-game symbol. Likewise
joystick run should now say hold \<run button\> or double tap to run where it makes sense".)*

**What was built** (PR #539). `HelpText` (`src/ui/help_text.gd`), a `RichTextLabel`, lays out a
line holding `{pause}` and `{run}` tokens with the atlas regions `ui/pause` and `ui/run` inline, a
square at the font size, centred on the text. The HUD's lesson label and the pause screen's body
are `HelpText`s. The pause lesson reads "Press" + the pause symbol + "to pause" in every scheme. In
joystick mode the day-1 line reads "Tap to walk, hold" + the run symbol + "or double tap to run",
and the first pursuit's "Hold" + the run symbol + "or double tap to run"; in tap mode both keep
"double tap to run". The pause screen's body is worded for the scheme in force each time it opens.
The title screen keeps "Tap to walk, double tap to run.", since the scheme is chosen there.
On day 1 the HUD says the walking lesson again when the scheme is chosen on the title
(`EventBus.controls_chosen`), so a run that picks joystick sees its own wording; the lesson now shows
its full seven seconds after the title rather than counting down behind it.
`docs/MECHANICS.md` describes the lines. Stills of each line in both schemes are in
`docs/evidence/freckled-lemur-help-icons-2026-10-04/`.

This changes, for joystick mode only, the 2026-09-07 wording "Double tap to run" (the player's
words above); the 2026-09-06 rule that nothing on screen names a key stands, since a symbol is the
on-screen button.

**Proposed, not asked for, and open to overturn:** the run button named in joystick mode only and
the pause symbol in every mode; the title's line unchanged; the symbol drawn as the button's own
art (a white disc), not tinted to the text colour, at the font size; "press" for pause and "hold"
for run, the player's verbs; the scheme read through a `touch_controls` group; the day-1 lesson shown after the title. Not captured: the
phone's portrait layout.
