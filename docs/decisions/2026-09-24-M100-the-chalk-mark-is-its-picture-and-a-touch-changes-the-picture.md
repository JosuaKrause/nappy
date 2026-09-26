## M100 — The chalk mark is its picture, and a touch changes the picture · built 2026-09-24

*([PLAYTEST-128](../playtests/PLAYTEST-128.md): "it's drawn in code even though a chalk_mark.svg
exists … Yes, we need to use the svg.")* `ContactPoint._draw_chalk()` draws
`art/props/chalk_mark.svg`, and `chalk_mark_touched.svg` once the mark is done, from the
`decoration` atlas group, centre-anchored where the code-drawn arc and lines stood, with the same
alpha flicker. `Palette.CHALK` is gone; `CHALK_DONE` stays for the HUD text that uses it.
`ContactPoint` acquires and releases the `decoration` group itself, as `ClosureMarker` does for
`street_kit`, because a bare mark in a test has no `City` holding the group for it.

**This also answers M100's older item, a touch on a chalk mark shows nothing at the moment but a
colour change** (playtest 50: "how do I know I stepped on the chalk"). Of its three options —
nothing more, the colour made unmistakable, or a status line — playtest 53 had already asked for
a fourth, a touched picture where she adds something to the mark, and that is what now shows at
the moment of the touch. Whether it reads is in `REVIEW.md`.

**Open to overturn, chosen by the agent:** the `decoration` group rather than `events`; keeping
the flicker as a modulate on the picture; the centre anchor, matching the SVGs' own. Stills:
`evidence/m100-chalk-mark-svg-2026-09-24/`.
