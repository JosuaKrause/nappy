## M100 — The basement vent is a floor grate, there between blows · built 2026-09-24

*(Found animating the steam, `DECISIONS.md`, M100, water, smoke and steam move: `steam.svg` drew the
pipe and the cloud as one picture and `InteriorEvents` keeps no instance between blows, so the vent
was on screen only while it steamed. "A vent that is there all the time, blowing or not, is what a
player can plan around.")*

**The pipe was tried first and rejected.** A standing pipe (`steam_pipe.svg`, cloud split off into
`steam.svg`/`steam_b.svg`) stood at every vent for the whole section, but a vent stands where the
basement corridor is one tile (32px) wide, which is what makes a blow a gate: a solid pipe, half
its 15px width plus her 14px body, would have shut the corridor for good, so she walked through
it. Asked whether she walks through a standing pipe, over a floor grate, or past a pipe against
the wall, the player: "Let's make it a vent" · "Floor grate". The pipe pass is kept under
`docs/evidence/m100-vent-pipe-2026-09-24/`, its SVGs in `svg/` and the rejection in its README.

**What is built.** `art/events/steam_grate.svg`: an iron grate seen from above, 24×16 on a 32×32
canvas, four bars and a crossbar over a dark shaft, corner bolts and a damp stain, centred on the
vent's point like the basement's other floor decals. `steam.svg` and `steam_b.svg` draw only the
cloud, rising out of the grate from their unchanged 32×48 bottom-centre anchor. `InteriorEvents.
_lay_a_grate()` adds it to the building at the floor tiles' layer and after them, so it is under
the walls and under the sorted layer where she and every blow stand; no body, no field; a restart
lays each once. `EventInstance.STEAM_GRATE`/`steam_grate()` name the picture. The steam's notice,
clocks, body and lethal geometry are unchanged. `tests/test_interior.gd` checks the grate at every
vent from placement, centred, drawn under her and under every blow, at the floor layer, laid once
per restart; moving it back into the sorted layer fails it on every vent.

**Open to overturn** (the agent's choices where the design was silent): the grate wider than tall
with a crossbar, since upright bars in a taller frame read as a barred window; frame b's gap
between the lifted cloud and the fresh puff, since a trail joining them read as a mushroom cloud;
the grate added from `InteriorEvents` rather than a method on `InteriorScene`, which was outside
the fence; the blow's shadow darkening the grate, as every solid row's does. No in-game frame shows
her standing on a grate; the test is the evidence for "under her". The player, shown the review
sheet (idle and blowing, at play size and under the basement's lighting): "Vent looks great".
