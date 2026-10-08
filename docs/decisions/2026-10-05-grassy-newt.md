# grassy-newt — A held push tears every sheet she slides past · 2026-10-05 · not from an entry


Inbox #591 in [olive-hedgehog](../playtests/2026-10-05-olive-hedgehog.md), said in a session on 2026-10-05: "I never tore a poster by accident. even when doing it
on purpose I have to make sure to tap for each poster in a row just walking by with diagonal held
only tears every second poster -- not sure if it actually should be this way". Offered three ways
for tearing to work, the player chose "option 1 for tearing": once she pushes, every sheet she
slides past tears. And on the accident: "the accidental tear statement is about how a player will
learn this mechanic -- this is still the case. we don't tutorialize this -- it's an easter egg".

**Why only every second sheet tore.** A tear needed the push held for `PosterWalls.PRESS_TO_TEAR`
(0.4s) in front of an intact sheet, and the clock started over after each tear; sliding along the
wall she reached the next sheet in less than that, so it escaped and the one after it tore.

**Built.** The first sheet of a push still takes the 0.4s. After it, while the push is held (her
heading into the wall, her feet at its face, on its front row), each intact sheet she comes in front
of tears at once. Letting go of the push, turning out of the wall or stepping off its face ends the
slide, and the next push waits its 0.4s again. Walking past without a push tears nothing. Every
sheet torn draws its own marble from the tears' bag, as before. `docs/MECHANICS.md` keeps that a
push can happen by accident, which is how tearing is found, and says nothing teaches it.

**Measured.** `tests/test_posters.gd` slides a held diagonal along six adjacent sheets at walking
pace: all six tear and six marbles are drawn; with the slide taken out, three tear. The stills
on PR #593 come from `scene-recipes/tear-slide.json` (day 8, four sheets on one wall): the sheets
she slides past are torn, the one she passed before the first 0.4s is intact.

**Chosen while building, open to overturn:** standing in front of a torn or bare stretch of the
wall with the push still held keeps the slide going, so a gap in the paper does not re-arm the
0.4s; only the push itself ending does.
