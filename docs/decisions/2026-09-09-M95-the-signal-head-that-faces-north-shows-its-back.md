## M95 — The signal head that faces north shows its back — 2026-09-09

[PLAYTEST-48.md](../playtests/PLAYTEST-48.md): *"the north facing traffic light shows the lights towards the
south. we should only see the back of it. the information is fully encoded in the south facing
one. let's make a proper north facing graphic"*.

Four heads stand at every signalled junction, each beside the carriageway it stops and facing the
traffic it stops. The two on the spine's arms shared one face-on drawing, so the head north of
the junction — facing north at the southbound traffic — showed three lamps to a camera looking at
it from the south. `assets/props/signal_head_back.svg` is the third drawing: the same post and
housing at the same height, a back plate with a mounting bracket, no lamps and no visors.
`TrafficLight.faces()` records a heading pointing down the screen as facing away; that head draws
the back, paints no lamp, and skips the per-frame lamp check since nothing on it changes. The
face-on head, the two edge-on heads and where every head stands are untouched.

Before and after on seed 4242 at `--spawn signal` are in `docs/evidence/` as
`shot-2026-09-09-seed4242-21d3ba2-signal-head-back-before.png` and `-after.png`; the north-west
head goes from a red lamp to a back plate and the other three are identical in both.
