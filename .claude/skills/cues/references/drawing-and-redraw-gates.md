# Drawing through `Sprites`, and the redraw gates

Read this before touching what `EventLook`, `CrowdAgent` or `EntityHalo` draw, the key a redraw
gate compares, `DrawnView`, or any caller of `Sprites.draw_standing()`.

The engine traps — a negative `Rect2`, `draw_set_transform` replacing rather than composing, Y-sort,
retained `_draw()` — are the **godot** skill, "Physics and drawing". Two things are specific to the
cues' own drawing:

**A caller that sets a canvas transform around a mirrored sprite publishes it.**
`Sprites.draw_standing()` is the only mirrored draw path in the game, and it can only set an
absolute matrix. So a caller pairs its own `draw_set_transform*` with
`Sprites.set_base_transform(canvas, base)`, which tells the canvas item being drawn on (the
transform is a property of that canvas's pass, held on it and read back by `draw_standing()`, not a
global), and sets it back to `Transform2D.IDENTITY` when the pass ends;
`Sprites.mirrored_transform(canvas, at)` composes the mirror under it. `EntityHalo._on_draw()`,
`EventLook.draw()` and `CrowdAgent._draw()` are the three callers. A caller that forgets draws every mirrored halo offset
on top of the body, with no rim.

**A redraw gate is a promise about everything the drawing reads.** An event's look (`EventLook`)
and `CrowdAgent` skip the rebuild while their picture is unchanged, so the key each compares has to
name every time-varying quantity its drawing touches, **not the ones that look like the
picture**. A term missing from the key is a frozen picture rather than a crash, and it shows only on
the bodies that reach the missing term — a car's registration and shadow read its **continuous**
heading while its view, mirror and gait are quantised. A traced rim makes such a freeze visible,
since `EntityHalo` re-draws the body every frame: the halo stands where the body belongs and the
body does not. Sweep the continuous quantity in a test and assert the key moved with it.

**A gate that skips off screen is a promise about everything the drawing covers, and it redraws on
its first frame back.** `DrawnView` (`src/ui/drawn_view.gd`) is the one box, the view grown by two
tiles, that `CrowdAgent` and an event's look skip their redraw and caret projection outside of. The
box a thing is tested against has to hold every pixel its drawing can reach, not the picture at its
own point: a street fire's flames run the whole burning front, hundreds of pixels from where it
stands, and a box of its point alone freezes them on screen. And it redraws on the first frame back
whatever its key says, since nothing kept the picture current while it was away, so a caret owed on
that frame is drawn on it.

**A headless run draws but makes no pixels**: it calls `_draw()` and emits `draw` like any other,
and its dummy renderer leaves no picture to judge — see the **verify** skill, "What each one cannot
see".
