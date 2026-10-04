priority: now

# freckled-lemur — A help text shows the button it means · filed 2026-10-04

[misty-toad, help texts show the button](../../playtests/2026-10-04-misty-toad.md) files inbox
#533, band `now` as the player labelled it:

> For example the press pause to pause text should say press \<pause button\> to pause where it uses the in-game symbol. Likewise joystick run should now say hold \<run button\> or double tap to run where it makes sense

**Asked for:** a help text that names an on-screen button shows that button's own in-game symbol
in the line, rather than describing it in words: the pause lesson reads "press" and then the pause
symbol and "to pause"; in joystick mode, the run lesson says hold the run button (its symbol) or
double tap to run, "where it makes sense".

**The texts today.** `HUD._teach_the_day()` says "Tap to walk, double tap to run" on day 1;
`HUD._teach_the_pause()` says "Tap the pause button to pause" (its comment: the button is an icon,
two bars, not a word); `HUD._on_event_telegraphed()` says "Double tap to run" at the first pursuit
of `Tuning.RUN_TAUGHT_DAY`; `PauseScreen._BODY` and `TitleScreen._BODY` both open "Tap to walk,
double tap to run." The symbols are the atlas regions `ui/pause` and `ui/run` that
`TouchControls` draws (`_PAUSE_ICON`, `_RUN_ICON`). Joystick mode's run buttons are described in
`docs/MECHANICS.md` (inbox #434: "for joystick mode a dedicated run button (one on each side next
to the joystick)").

**What it changes.** The run line's wording was fixed on 2026-09-07 ("the movement tutorial should
just say 'Tap to walk' and 'Double tap to run'", `PauseScreen._BODY`'s doc); the player's words
here change it for joystick mode, where a run button exists. One wording for every *device*
(2026-09-06: no key is named on screen) stays: a symbol is the on-screen button, not a key.

**Proposed, not asked for:**

- "Where it makes sense" read as: the run line names the run button only in joystick mode, where
  the button is on screen; in tap mode it stays "double tap to run". The pause line shows the
  symbol in every mode, since the pause button is always drawn. The title screen, shown before a
  scheme is in play, follows the scheme the save holds.
- The symbol drawn inline in the text at the text's own height, in the text's colour, through a
  label that can place an image in a line (a `RichTextLabel` with the atlas region), so it reads
  as the same glyph the button wears.
- The verb: the player wrote "press" for the pause line and "hold" for the run button; those words
  are used, and "tap" stays for walking.
