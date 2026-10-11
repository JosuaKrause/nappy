# spry-pelican — The title's two joystick buttons say L and R · 2026-10-11

[azure-puffin](../playtests/2026-10-10-azure-puffin.md), inbox #665:

> in the start screen add a little L and R to the two joystick buttons to make it clear that they
> lead to different settings

**A letter on the button, not a caption.** `ModeButton.letter` (`src/ui/mode_button.gd`), when set,
adds a mouse-ignoring `Label` named `Letter` in the game's UI font, size 18, in the joystick icon's
colour (`Palette.BUTTON_SYMBOL`), in the lower-right of the disc beside the icon.
`scenes/ui/title_screen.tscn` sets "L" on the left joystick button and "R" on the right; the Tap to
Go button has none. The captions stay "On-screen Controls" and "Tap to Go"
([PLAYTEST-34](../playtests/PLAYTEST-34.md): "call the modes 'On-screen Controls' and 'Tap to Go' no
further explanations"), and which side each button sets is
[leafy-marten](2026-10-10-leafy-marten.md)'s. A `Label` is text, not drawing, so the rule that
`mode_button.gd` draws nothing in code holds; no SVG variant of `art/ui/joystick.svg` was made.
`tests/test_main.gd` checks the left and right buttons carry L and R and the Tap button none. The
still is [title-lr-2026-10-11](../evidence/title-lr-2026-10-11/title.png).

*Chosen where the entry was silent, open to overturn:* the letter's place (lower-right of the
disc), its size (18) and no outline; and the two letters are scene properties rather than entries
in a text catalogue, since polite-finch, one catalogue holds every text the game shows, has not
landed.
