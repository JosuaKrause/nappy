priority: now

# spry-pelican — The title's two joystick buttons say L and R · filed 2026-10-10

[azure-puffin](../../playtests/2026-10-10-azure-puffin.md), inbox #665:

> in the start screen add a little L and R to the two joystick buttons to make it clear that they
> lead to different settings

The two buttons are the title screen's left and right `ModeButton`s (`src/ui/title_screen.gd`,
`scenes/ui/title_screen.tscn`), both drawing the joystick symbol and sharing the caption
"On-screen Controls"; [leafy-marten](../../decisions/2026-10-10-leafy-marten.md) made the left one
set the left side to the joystick and the right one the right side. The work is
[l-and-r.md](l-and-r.md).
