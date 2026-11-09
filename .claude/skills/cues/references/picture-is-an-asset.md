# A picture is an asset, never code: the rule in full

Read this before drawing anything in a `_draw()` that a person would call an image, and before
painting a button, an icon or a glyph in code.

**Anything that is a *picture* — a glyph, an icon, a silhouette, a symbol — is authored as an image
file under `art/` and drawn as a texture, never assembled at runtime out of `draw_circle`,
`draw_rect`, `draw_line`, `draw_arc` or `draw_colored_polygon`** (PLAYTEST-29 3). The **godot**
skill carries the short version for every `_draw()`; this is the rule in full.

**The caret is the one exemption.** `Sprites.draw_caret()` assembles it from
`draw_colored_polygon()` and an outline, because its width and colour are live state: it breathes
with the emission and its colour is the projection. It stays one shape drawn from one place, which
is what the rule protects, and nothing else in the vocabulary takes the exemption by analogy.

**SVG or PNG, and which one is the asset's own question rather than this rule's.** SVG is the
default for a glyph or a flat symbol, because it stays hand-editable; a painted or generated sheet
is a PNG, and both satisfy the rule for the same reason — a file a person can open.

**An icon or a symbol on a control is not "graphics" in the sense anything else in this project uses
the word** (PLAYTEST-29 3). So no argument about where drawing work sits in the queue is ever cover
for painting a button in `_draw()`.

**The reason is the feedback loop, and it is decisive** (woolly-finch 3): An SVG can be opened and
looked at — by a person, or by an agent reading the file — and judged on its own. A picture
assembled in `_draw()` can only be judged by booting the game and taking a screenshot, and **the
same headless run that proves the code correct proves nothing about whether it looks like anything
at all.** And an asset is **replaceable without touching code**: a consumer holds the region name
`ui/joystick`, which is whatever `art/ui/joystick.svg` was baked from, so a better drawing is a
drop-in.

**What this does not cover.** A shape that is *layout* rather than a picture — `MeterBar`'s fill, a
scrim, a debug overlay, a pressed button's fill, a knob whose position is live state. The line is
whether a person would call the result an *image*: a joystick, a hand and a fence are.

**Prefer the engine's data over any drawing at all.** A `Button`'s circular fill is a
`StyleBoxFlat` with corner radii and per-state overrides, not a painted disc; its glyph is the
button's own `icon`. Reaching for `_draw()` on a `Control` is the tell that a `StyleBox`, an
`icon` or a `TextureRect` was the answer.
