# minty-quail — The drawing suites read what is drawn; a headless run does call _draw() (tests through public seams) · 2026-11-03

minty-quail's `tests-public-seams.md` and `run-state-handed-in.md`: the drawing suites (the danger
halo, its rims and badge, the drawn and visible views, danger, the draw layers, the sentence lines).
All nine converted; five read no private member, and the item lists what the other four read.

**Found:** a headless run calls `_draw()` and emits `draw` like any other; its dummy renderer
makes no pixels. A probe counted a halo rim's traced copies in a headless suite. The verify and
cues skills, `docs/ARCHITECTURE.md`, `docs/EVENTS.md` and thirteen comments in ten code and suite files said a
headless run never calls `_draw()`; each keeps its point (a headless pass does not prove the
picture) with the true reason. Record minty-quail-44 dropped two halo wiring checks from
`tests/test_car_views.gd` on the old premise ("halo redraws the same body", "halo rides the bob");
they are back, read through an atlas the car is handed that notes each region a traced copy asks
for and where the copy stands.

**Built.**
- No seam under `src/`; one false doc clause in `src/ui/entity_halo.gd` fixed.
- The suites read what is drawn: how many copies a rim traces per frame, when the badge edge
  redraws (its `draw` signal), a rim's colour and alpha from the value its shader is handed. Fakes
  go in through the game's own inputs: a decayed baby handed to `ExcitementHalo.setup()`, a rim that
  records what the halo told it set as `ExcitementSource.rim`, an east-west street map handed to
  `EventInstance.setup()` (`tests/east_west_street.gd`); `tests/halo_rig.gd` is shared. Every event
  and badge living through real frames is handed the events' atlas page, as the game hands it.
- The stroller warning in `test_danger.gd` expires on real physics ticks, one per frame, and is
  cleared through the warnings' own `stand_down()`. The sentence suites call `break_for_label()`,
  which every screen's label calls, and show each sentence alone in the screen's real label, which
  must fit it on one line; before, the helper's own width estimate graded itself. They hand the
  screens a fresh `RunState`.
- Private-read lines 153 to 27, hand-called frames 33 to 0, `GameState` lines 8 to 0. Every check
  kept; four guards added. About forty mutation runs.
- A latent flake fixed: a manager's physics tick turned off before it entered the tree came back
  on when it entered; it is turned off after.

- The first review found three halo checks that passed or failed on frame length alone (a walk
  moved per frame while the fades ran on frame time; the strong-pick order read within one frame,
  which a long frame could fill with two blocks); the walk is laid out in steps of frame time and
  the strong-pick rule is read on every frame, holding at 30, 80 and 150 ms frames.

**Open to overturn** (the builder's choices where the brief was silent): the halo checks count
frame time (the rims ease on process frames), not physics ticks; the retired-holder test queues its
body between the physics step and the halo's pass; the cyclist under the covered corner steps a
fixed 1/60 s per frame. `test_halo.gd` takes about 12.7 s instead of 0.26 s, since its fades and
turnovers run in real time.
