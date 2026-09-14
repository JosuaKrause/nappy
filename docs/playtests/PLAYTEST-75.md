# Playtest 75 — 2026-09-14

A desktop debug session, reported in one sentence on 2026-09-14.

## A layer turned off leaves its last picture behind

> "pressing number keys to turn off a layer doesn't remove the layer anymore. for example if I
> press 2 twice I have ghost circles all over"

`2` is the shadow-outline layer; the circles are the walkers' shadow outlines, still on
screen after the key turned the layer off. Filed as M142 in `TODO.md`. The cause is read from
the code there: the layer node asks for a redraw only while a layer is on, and a retained
`_draw()` keeps its last picture until the next redraw, so the frame that turns the last layer
off is never drawn.
